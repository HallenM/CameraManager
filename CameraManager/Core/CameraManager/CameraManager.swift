//
//  CameraManager.swift
//  CameraManager
//
//  Created by Moshkina on 08.09.2021.
//

import Foundation
import UIKit
import AVFoundation

protocol CameraCaptureDelegate: AnyObject {
    func cameraCaptureDidStart(_ capture: CameraManager)
    func cameraCaptureDidStop(_ capture: CameraManager)
}

class CameraManager: NSObject {
    var previewLayer: AVCaptureVideoPreviewLayer
    
    weak var delegate: CameraCaptureDelegate?
    
    private var videoDevice: AVCaptureDevice?
    private var audioDevice: AVCaptureDevice?
    
    private(set) var devicePosition: AVCaptureDevice.Position
    let preset: AVCaptureSession.Preset
    private var currentOrientation: AVCaptureVideoOrientation = .portrait
    
    private(set) var session: AVCaptureSession?
    
    weak var videoWriter: VideoWriter?
    
    var isRunning: Bool {
        return session?.isRunning ?? false
    }
    
    private var isFlashlightOn: Bool = false
    
    private var videoDataOutput: AVCaptureVideoDataOutput {
        let output = AVCaptureVideoDataOutput()
        output.videoSettings = [
            kCVPixelBufferPixelFormatTypeKey as String: kCVPixelFormatType_32BGRA
        ]
        output.alwaysDiscardsLateVideoFrames = true
        output.setSampleBufferDelegate(self, queue: DispatchQueue.global(qos: .userInitiated))
        
//        if let videoConnection = output.connection(with: .video) {
//            if videoConnection.isVideoMirroringSupported {
//                videoConnection.automaticallyAdjustsVideoMirroring = false
//                videoConnection.isVideoMirrored = true
//            }
//        }
        
//        if isFrontCamera() {
//            if let videoOutput = session?.outputs.first(where: { ($0 as? AVCaptureVideoDataOutput) != nil}),
//               let videoConnection = videoOutput.connection(with: .video) {
//                if videoConnection.isVideoMirroringSupported {
//                    videoConnection.automaticallyAdjustsVideoMirroring = false
//                    videoConnection.isVideoMirrored = true
//                }
//            }
//        }
        
        return output
    }
    
    private var audioDataOutput: AVCaptureAudioDataOutput {
        let output = AVCaptureAudioDataOutput()
        output.setSampleBufferDelegate(self, queue: DispatchQueue.global(qos: .userInitiated))
        return output
    }
    
    init(devicePosition: AVCaptureDevice.Position = .front,
         preset: AVCaptureSession.Preset = .high) throws {
        #if targetEnvironment(simulator)
            throw CameraError(code: 505,
                              description: "Simulator don't work with video")
        #endif
        
        self.devicePosition = devicePosition
        self.preset = preset
        
        self.previewLayer = AVCaptureVideoPreviewLayer()
        self.previewLayer.videoGravity = AVLayerVideoGravity.resizeAspectFill
        
        let videoDevices = CameraInputDevice.availableDevices(position: devicePosition)
        guard !videoDevices.isEmpty else {
            throw CameraError(code: 1020,
                              description: "Don't allow any camera devices")
        }
        guard let videoDevice = videoDevices.first(where: { $0.supportsSessionPreset(preset) }) else {
            throw CameraError(code: 1020,
                              description: "No device supports preset: \(preset)")
        }
        self.videoDevice = videoDevice
        
        guard let audioDevice = AVCaptureDevice.default(for: .audio) else {
            throw CameraError(code: 1020, description: "Don't allow any audio devices")
        }
        self.audioDevice = audioDevice
    }
    
    private func videoDeviceInput() throws -> AVCaptureDeviceInput {
        guard let videoDevice = videoDevice else {
            throw CameraError(code: 1020,
                              description: "Not configurate video device")
        }
        return try AVCaptureDeviceInput(device: videoDevice)
    }
    
    private func audioDeviceInput() throws -> AVCaptureDeviceInput {
        guard let audioDevice = audioDevice else {
            throw CameraError(code: 1020,
                              description: "Not configurate audio device")
        }
        return try AVCaptureDeviceInput(device: audioDevice)
    }
    
    func setVideoInputs() throws {
        guard let session = session else {
            return
        }
        
        session.beginConfiguration()
        if let inputs = session.inputs as? [AVCaptureDeviceInput] {
            for input in inputs.filter({$0.device == self.videoDevice}) {
                session.removeInput(input)
            }
        }
        
        let videoDevices = CameraInputDevice.availableDevices(position: devicePosition)
        
        guard !videoDevices.isEmpty else {
            throw CameraError(code: 1020,
                              description: "Don't allow any camera devices")
        }
        guard let videoDevice = videoDevices.first(where: { $0.supportsSessionPreset(preset) }) else {
            throw CameraError(code: 1020,
                              description: "No device supports preset: \(preset)")
        }
        
        self.videoDevice = videoDevice
        
        let videoDeviceInput = try self.videoDeviceInput()
        
        guard session.canAddInput(videoDeviceInput) else {
            self.session = nil
            throw CameraError(code: 1020,
                              description: "Capture Session can't add \(videoDeviceInput)")
        }
        
        session.addInput(videoDeviceInput)
        session.commitConfiguration()
    }
    
    func start() throws {
        guard self.session == nil else {
            return
        }
        
        let videoDeviceInput = try self.videoDeviceInput()
        let audioDeviceInput = try self.audioDeviceInput()
        
        let session = AVCaptureSession()
        session.sessionPreset = preset
        session.automaticallyConfiguresApplicationAudioSession = false
        
        self.previewLayer.session = session
        self.session = session
        
        guard session.canAddOutput(videoDataOutput) else {
            self.session = nil
            throw CameraError(code: 1020,
                              description: "Capture Session can't add \(videoDataOutput)")
        }
        
        guard session.canAddOutput(audioDataOutput) else {
            self.session = nil
            throw CameraError(code: 1020,
                              description: "Capture Session can't add \(audioDataOutput)")
        }
        
        guard session.canAddInput(videoDeviceInput) else {
            self.session = nil
            throw CameraError(code: 1020,
                              description: "Capture Session can't add \(videoDeviceInput)")
        }
        
        guard session.canAddInput(audioDeviceInput) else {
            self.session = nil
            throw CameraError(code: 1020,
                              description: "Capture Session can't add \(audioDeviceInput)")
        }
        
        session.beginConfiguration()
        session.addInput(videoDeviceInput)
        session.addOutput(videoDataOutput)
        session.addInput(audioDeviceInput)
        session.addOutput(audioDataOutput)
        session.commitConfiguration()
        
        changeOrientation(orientation: currentOrientation)
        
        session.startRunning()
        
        DispatchQueue.main.async {
            self.delegate?.cameraCaptureDidStart(self)
        }
    }
    
    func stop() {
        guard let session = session,
            session.isRunning else {
                self.session = nil
                return
        }
        session.stopRunning()
        self.session = nil
        
        DispatchQueue.main.async {
            self.delegate?.cameraCaptureDidStop(self)
        }
    }
    
    func changeOrientation(orientation: AVCaptureVideoOrientation) {
        if let previewConnection = self.previewLayer.connection {
            if previewConnection.isVideoOrientationSupported {
                previewConnection.videoOrientation = orientation
            }
        }
        
        if let videoOutput = session?.outputs.first(where: { ($0 as? AVCaptureVideoDataOutput) != nil}),
           let videoConnection = videoOutput.connection(with: .video) {
            if videoConnection.isVideoOrientationSupported {
                videoConnection.videoOrientation = orientation
            }
        }
        currentOrientation = orientation
    }
    
    func flipCaptureDevicePosition() throws {
        self.devicePosition = self.devicePosition == .back ? .front : .back
        
        try setVideoInputs()
        
        changeOrientation(orientation: currentOrientation)
        
        if !isFrontCamera() {
            if !toggleFlashlight() {
                throw CameraError(code: -2000, description: "Problem with flashlight")
            }
        }
    }
    
    func isFrontCamera() -> Bool {
        return devicePosition == .front
    }
    
    func toggleFlashlight(force: Bool = false) -> Bool {
        guard let session = session else {
            return false
        }
        
        var isSucceed = false
        
        session.beginConfiguration()
        
        if let videoDevice = videoDevice, videoDevice.hasTorch && videoDevice.isTorchAvailable {
            do {
                try videoDevice.lockForConfiguration()
                if force {
                    isFlashlightOn = !isFlashlightOn
                }
                
                videoDevice.torchMode = (!isFrontCamera() && isFlashlightOn) ? .on : .off
                
                videoDevice.unlockForConfiguration()
                isSucceed = true
            } catch let error {
                print("Failed to set up torch level with error \(error)")
                isSucceed =  false
            }
        }
        
        session.commitConfiguration()
        
        return isSucceed
    }
}

extension CameraManager: AVCaptureVideoDataOutputSampleBufferDelegate {
    func captureOutput(_ output: AVCaptureOutput,
                       didOutput sampleBuffer: CMSampleBuffer,
                       from connection: AVCaptureConnection) {
        guard let formatDesc = CMSampleBufferGetFormatDescription(sampleBuffer) else { return }
        let mediaType = CMFormatDescriptionGetMediaType(formatDesc)
        if mediaType == kCMMediaType_Audio {
            handleAudioSampleBuffer(buffer: sampleBuffer)
        } else if mediaType == kCMMediaType_Video {
            handleVideoSampleBuffer(buffer: sampleBuffer)
        }
    }
    
    private func handleVideoSampleBuffer(buffer: CMSampleBuffer) {
        guard self.isRunning else {
            return
        }
        
        let sampleTime = CMSampleBufferGetPresentationTimeStamp(buffer)
        guard let pixelBuffer = CMSampleBufferGetImageBuffer(buffer) else { return }
              
        try? self.videoWriter?.addPixelBuffer(pixelBuffer, sampleTime: sampleTime)
    }
}

extension CameraManager: AVCaptureAudioDataOutputSampleBufferDelegate {
    private func handleAudioSampleBuffer(buffer: CMSampleBuffer) {
        guard self.isRunning else {
            return
        }
        try? self.videoWriter?.addAudioSampleBuffer(buffer)
    }
}
