//
//  CameraManager.swift
//  CameraManager
//
//  Created by Moshkina on 08.09.2021.
//

import Foundation
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
    
    private(set) var session: AVCaptureSession?
    
    var isRunning: Bool {
        return session?.isRunning ?? false
    }
    
    private var videoDataOutput: AVCaptureVideoDataOutput {
        let output = AVCaptureVideoDataOutput()
        output.videoSettings = [
            kCVPixelBufferPixelFormatTypeKey as String: kCVPixelFormatType_32BGRA
        ]
        output.alwaysDiscardsLateVideoFrames = true
        output.setSampleBufferDelegate(self, queue: DispatchQueue.global(qos: .userInitiated))
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
    
    func flipCaptureDevicePosition() throws {
        self.devicePosition = self.devicePosition == .back ? .front : .back
        try setVideoInputs()
    }
}

extension CameraManager: AVCaptureVideoDataOutputSampleBufferDelegate {
    
}

extension CameraManager: AVCaptureAudioDataOutputSampleBufferDelegate {
    
}
