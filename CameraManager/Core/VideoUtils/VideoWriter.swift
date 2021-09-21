//
//  VideoWriter.swift
//  CameraManager
//
//  Created by Moshkina on 13.09.2021.
//

import UIKit
import AVFoundation
import CoreData

protocol VideoWriterDelegate: AnyObject {
    func didBeginWriting(_ videoWriter: VideoWriter)
    func videoWriter(_ videoWriter: VideoWriter, didStopWritingVideoTo url: URL)
    func videoWriter(_ videoWriter: VideoWriter, didFailedWritingVideoWith error: Error)
}

final class VideoWriter {
    weak var delegate: VideoWriterDelegate?
    
    private let deviceRgbColorSpace = CGColorSpaceCreateDeviceRGB()
    
    private var isVideoWritingStarted = false
    
    private var assetWriter: AVAssetWriter?
    private var assetWriterAudioInput: AVAssetWriterInput?
    private var assetWriterVideoInput: AVAssetWriterInput?
    private(set) var assetWriterInputPixelBufferAdaptor: AVAssetWriterInputPixelBufferAdaptor?
    
    private var currentAudioSampleBufferFormatDescription: CMFormatDescription?
    private let currentVideoDimensions: CMVideoDimensions
    private var currentVideoTime = CMTime()
    private var startRecordingTime: CMTime = CMTime()
    
    private var backgroundRenderingID: UIBackgroundTaskIdentifier = .invalid
    
    let lock = DispatchSemaphore(value: 1)
    
    func isRecording() -> Bool {
        lock.wait()
        let isRecord = isStartRecording
        lock.signal()
        return isRecord
    }
    
    private var isStartRecording: Bool = false
    
    init(frameSize: CGSize = CGSize(width: 1280, height: 720)) {
        currentVideoDimensions = CMVideoDimensions(
            width: Int32(frameSize.width),
            height: Int32(frameSize.height)
        )
    }
}

private extension VideoWriter {
    
   func makeAssetWriterVideoInput() -> AVAssetWriterInput {
        let settings: [String: Any] = [
            AVVideoCodecKey: AVVideoCodecType.h264,
            AVVideoWidthKey: currentVideoDimensions.width,
            AVVideoHeightKey: currentVideoDimensions.height
        ]
        
        let input = AVAssetWriterInput(mediaType: .video, outputSettings: settings)
        input.expectsMediaDataInRealTime = true
//        input.transform = orientationOptions.affineTransform(with: .zero)
        
        return input
    }
    
    func makeAssetWriterAudioInput(settings: [String: Any]?) -> AVAssetWriterInput {
        let assetWriterAudioInput = AVAssetWriterInput(mediaType: .audio, outputSettings: settings)
        assetWriterAudioInput.expectsMediaDataInRealTime = true
        
        return assetWriterAudioInput
    }
    
    // create a pixel buffer adaptor for the asset writer; we need to obtain pixel buffers for rendering later from its pixel buffer pool
    func makeAssetWriterInputPixelBufferAdaptor(with input: AVAssetWriterInput) -> AVAssetWriterInputPixelBufferAdaptor {
        let attributes: [String: Any] = [
            kCVPixelBufferPixelFormatTypeKey as String: kCVPixelFormatType_32BGRA,
            kCVPixelBufferWidthKey as String: currentVideoDimensions.width,
            kCVPixelBufferHeightKey as String: currentVideoDimensions.height,
            kCVPixelBufferCGImageCompatibilityKey as String: kCFBooleanTrue!
        ]
        return AVAssetWriterInputPixelBufferAdaptor(
            assetWriterInput: input,
            sourcePixelBufferAttributes: attributes
        )
    }
    
    func makeAudioCompressionSettings() throws -> [String: Any] {
        guard let currentAudioSampleBufferFormatDescription = currentAudioSampleBufferFormatDescription else {
            print("Failed get format description")
            throw AVError(.unknown)
        }
        
        let channelLayoutData: Data
        var layoutSize: size_t = 0
        if let channelLayout = CMAudioFormatDescriptionGetChannelLayout(currentAudioSampleBufferFormatDescription, sizeOut: &layoutSize) {
            channelLayoutData = Data(bytes: channelLayout, count: layoutSize)
        } else {
            channelLayoutData = Data()
        }
        
        guard let basicDescription = CMAudioFormatDescriptionGetStreamBasicDescription(currentAudioSampleBufferFormatDescription) else {
            print("Failed get format description")
            throw AVError(.unknown)
        }
        
        // record the audio at AAC format, bitrate 64000, sample rate and channel number using the basic description from the audio samples
        return [
            AVFormatIDKey: kAudioFormatMPEG4AAC,
            AVNumberOfChannelsKey: basicDescription.pointee.mChannelsPerFrame,
            AVSampleRateKey: basicDescription.pointee.mSampleRate,
            AVEncoderBitRateKey: 64000,
            AVChannelLayoutKey: channelLayoutData
        ]
    }
}

extension VideoWriter {
    func addPixelBuffer(_ pixelBuffer: CVPixelBuffer, sampleTime: CMTime) throws {
        lock.wait()
        let assetWriter = self.assetWriter
        let isRecording = self.isStartRecording
        let assetWriterVideoInput = self.assetWriterVideoInput
        let assetWriterInputPixelBufferAdaptor = self.assetWriterInputPixelBufferAdaptor
        let isWritingStarted = self.isVideoWritingStarted
        let currentAudioSampleBufferFormatDescription = self.currentAudioSampleBufferFormatDescription
        lock.signal()
        
        guard isRecording, currentAudioSampleBufferFormatDescription != nil else { return }
        guard let writer = assetWriter,
              let videoInput = assetWriterVideoInput,
              let pixelBufferAdaptor = assetWriterInputPixelBufferAdaptor else {
            print("Failed get buffer adaptor")
            throw AVError(.unknown)
        }
        if !isWritingStarted {
            try self.internalStartSession(sampleTime: sampleTime)
        }
        
        if sampleTime < startRecordingTime { return }
        
        lock.wait()
        self.currentVideoTime = sampleTime
        lock.signal()
        
        guard videoInput.isReadyForMoreMediaData,
              writer.status == .writing else {
            print("Failed write video buffer")
            throw writer.error ?? AVError(.unknown)
        }
        
        guard CVPixelBufferLockBaseAddress(pixelBuffer, []) == kCVReturnSuccess else {
            print("Failed write video buffer")
            throw AVError(.unknown)
        }
        defer {
            CVPixelBufferUnlockBaseAddress(pixelBuffer, [])
        }
        
        pixelBufferAdaptor.append(pixelBuffer, withPresentationTime: sampleTime)
    }
    
    func addAudioSampleBuffer(_ sampleBuffer: CMSampleBuffer) throws {
        guard let formatDesc = sampleBuffer.formatDescription else {
            print("Faield get format description")
            throw AVError(.unknown)
        }
        
        lock.wait()
        self.currentAudioSampleBufferFormatDescription = formatDesc
        let assetWriter = self.assetWriter
        let isRecording = self.isStartRecording
        let isWritingStarted = self.isVideoWritingStarted
        let assetWriterAudioInput = self.assetWriterAudioInput
        lock.signal()
        
        if sampleBuffer.presentationTimeStamp < startRecordingTime { return }
        
        guard isRecording, isWritingStarted else { return }
        
        guard assetWriter != nil,
              let input = assetWriterAudioInput,
              input.isReadyForMoreMediaData,
              input.append(sampleBuffer) else {
            print("Failed write audio buffer")
            throw AVError(.unknown)
        }
    }
}

private extension VideoWriter {
    func internalSetup(outputURL: URL) throws {
        try? FileManager.default.removeItem(at: outputURL)
        
        let newAssetWriter = try AVAssetWriter(url: outputURL, fileType: .mp4)
        
        let newAssetWriterVideoInput = self.makeAssetWriterVideoInput()
        guard newAssetWriter.canAdd(newAssetWriterVideoInput) else {
            lock.wait()
            self.assetWriterVideoInput = nil
            lock.signal()
            print("Can't add video input")
            throw AVError(.unknown)
        }
        newAssetWriter.add(newAssetWriterVideoInput)
        
        let newAssetWriterInputPixelBufferAdaptor = self.makeAssetWriterInputPixelBufferAdaptor(with: newAssetWriterVideoInput)
        let audioCompressionSettings = try? self.makeAudioCompressionSettings()
        guard newAssetWriter.canApply(
            outputSettings: audioCompressionSettings,
            forMediaType: .audio
        ) else {
            print("Can't apply audio settings")
            throw AVError(.unknown)
        }
        let newAssetWriterAudioInput = makeAssetWriterAudioInput(settings: audioCompressionSettings)
        
        guard newAssetWriter.canAdd(newAssetWriterAudioInput) else {
            lock.wait()
            self.assetWriterAudioInput = nil
            lock.signal()
            print("Can't add audio input")
            throw AVError(.unknown)
        }
        newAssetWriter.add(newAssetWriterAudioInput)
        
        guard newAssetWriter.startWriting() else {
            print("Failed start writing")
            throw AVError(.unknown)
        }
        
        lock.wait()
        self.isVideoWritingStarted = false
        self.assetWriter = newAssetWriter
        self.assetWriterAudioInput = newAssetWriterAudioInput
        self.assetWriterVideoInput = newAssetWriterVideoInput
        self.assetWriterInputPixelBufferAdaptor = newAssetWriterInputPixelBufferAdaptor
        lock.signal()
    }
    
    func internalStartSession(sampleTime: CMTime) throws {
        lock.wait()
        let assetWriter = self.assetWriter
        lock.signal()
        
        guard let writer = assetWriter else {
            print("Failed get asset writer")
            abortRecording()
            throw AVError(.unknown)
        }
        startRecordingTime = sampleTime
        writer.startSession(atSourceTime: sampleTime)
        
        lock.wait()
        self.isVideoWritingStarted = true
        lock.signal()
    }
    
    func internalReset() {
        lock.wait()
        assetWriterVideoInput = nil
        assetWriterAudioInput = nil
        assetWriterInputPixelBufferAdaptor = nil
        assetWriter = nil
        
        isVideoWritingStarted = false
        isStartRecording = false
        lock.signal()
    }
    
    func internalStop() {
        lock.wait()
        let isWritingStarted = self.isVideoWritingStarted
        let assetWriter = self.assetWriter
        let currentVideoTime = self.currentVideoTime
        lock.signal()
        
        internalReset()
        
        guard isWritingStarted,
              let writer = assetWriter else {
            DispatchQueue.main.async {
                self.delegate?.videoWriter(self, didFailedWritingVideoWith: AVError(.unknown))
            }
            return
        }
        
        writer.endSession(atSourceTime: currentVideoTime)
        writer.finishWriting { [weak self] in
            guard let self = self else { return }
            switch writer.status {
            case .failed:
                let error = writer.error ?? AVError(.unknown)
                DispatchQueue.main.async {
                    self.delegate?.videoWriter(self, didFailedWritingVideoWith: error)
                }
            case .completed:
                DispatchQueue.main.async {
                    self.delegate?.videoWriter(self, didStopWritingVideoTo: writer.outputURL)
                }
            default:
                break
            }
        }
    }
}

extension VideoWriter {
    func startRecording(to outputURL: URL) {
        let app = UIApplication.shared
        
        backgroundRenderingID = app.beginBackgroundTask(expirationHandler: {
            app.endBackgroundTask(self.backgroundRenderingID)
            self.backgroundRenderingID = UIBackgroundTaskIdentifier.invalid
        })
        
        do {
            try self.internalSetup(outputURL: outputURL)
            lock.wait()
            self.isStartRecording = true
            lock.signal()
            self.delegate?.didBeginWriting(self)
        } catch {
            self.abortRecording()
        }
    }
    
    func abortRecording() {
        lock.wait()
        let assetWriter = self.assetWriter
        let isRecording = self.isStartRecording
        let isWritingStarted = self.isVideoWritingStarted
        let videoTime = self.currentVideoTime
        lock.signal()
        
        self.internalReset()
        
        guard isRecording,
            isWritingStarted,
            let writer = assetWriter else {
                return
        }
        
        writer.endSession(atSourceTime: videoTime)
        writer.cancelWriting()
        
        // remove the temp file
        let fileURL = writer.outputURL
        try? FileManager.default.removeItem(at: fileURL)
        
        if backgroundRenderingID != .invalid {
            UIApplication.shared.endBackgroundTask(backgroundRenderingID)
        }
    }
    
    func stopRecording() {
        self.internalStop()
        if backgroundRenderingID != .invalid {
            UIApplication.shared.endBackgroundTask(backgroundRenderingID)
        }
    }
}
