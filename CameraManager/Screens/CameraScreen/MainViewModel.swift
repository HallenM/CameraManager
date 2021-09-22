//
//  MainViewModel.swift
//  CameraManager
//
//  Created by Moshkina on 06.09.2021.
//

import UIKit
import AVFoundation
import CoreData

enum CameraState {
    case initialized
    case interrupted
    case working
    case writing
    case stopped
}

class MainViewModel {
    weak var viewDelegate: ViewModelDisplayDelegate?
    
    var cameraManager: CameraManager?
    var videoWriter: VideoWriter?
    
    var previewLayer: AVCaptureVideoPreviewLayer? {
        return cameraManager?.previewLayer
    }
    
    var isRecording: Bool = false
    
    private var isFlashLightOn = false
    
    private var video: Video?
    
    private var cameraState: CameraState? {
        didSet {
            cameraStateHandler()
        }
    }
    
    init() {
        do {
            try cameraManager = CameraManager()
            cameraManager?.delegate = self
            checkCameraAndMicAuthorization()
        } catch {
            print(CameraError(code: 404,
                              description: "CameraManager cannot initialized"))
        }
        videoWriter = VideoWriter()
        videoWriter?.delegate = self
        cameraManager?.videoWriter = videoWriter
    }
    
    func cameraStateHandler() {
        guard let sessionState = cameraState else { return }
        
        switch sessionState {
        case .initialized:
            guard let cameraManager = cameraManager else { return }
            viewDelegate?.showPreview(self, previewLayer: cameraManager.previewLayer)
            if cameraManager.isFrontCamera() {
                viewDelegate?.showFlashlight(self, isFrontCamera: true)
            } else {
                viewDelegate?.showFlashlight(self, isFrontCamera: false)
            }
        case .interrupted:
            isRecording = !isRecording
            viewDelegate?.didChangeRecordState(self, isRecording: isRecording)
            saveVideo()
            viewDelegate?.showAlert(self, title: "Session Interrupted", message: "Session was interrupted. Video file was saved.", showSettings: false)
        case .writing:
            saveVideo()
        case .working:
            break
        case .stopped:
            break
        }
    }
    
    func saveVideo() {
        guard let url = video?.url else { return }
        let thumbnail = ThumbnailGenerator.generateThumbnail(for: url)
        
        if let thumbnail = thumbnail {
            video?.thumbnail = thumbnail.toData()
        }
        
        do {
            try video?.managedObjectContext?.save()
        } catch {
            print("Failure to save context: \(error)")
        }
        
//        appDelegate.saveContext(backgroundContext: context)
        
        // Get data
        guard let appDelegate = UIApplication.shared.delegate as? AppDelegate else { return }
        let context = appDelegate.persistentContainer.viewContext
        
        do {
            let fetchRequest: NSFetchRequest<Video> = Video.fetchRequest()
            let objects = try context.fetch(fetchRequest)
            let video = objects.last
            var image: UIImage?
            
            if let thumbnail = video?.thumbnail {
                image = UIImage().toImage(data: thumbnail)
            }
            print("CoreData Success: \(objects)")
        } catch {
            print("Error CoreData: \(error)")
        }
    }
}

extension  MainViewModel: ViewModelProtocol {
    // MARK: IBActions
    func didTapEnabledCameraButton() {
        let authorizationStatus = AVCaptureDevice.authorizationStatus(for: .video)
        
        switch authorizationStatus {
        case .notDetermined:
            AVCaptureDevice.requestAccess(for: .video) { [weak self] success in
                guard let self = self else { return }
                if success {
                    self.checkCameraAndMicAuthorization()
                    self.viewDelegate?.changeCameraButton(self, authorizationStatus: .authorized)
                } else {
                    self.viewDelegate?.changeCameraButton(self, authorizationStatus: .denied)
                }
            }
        case .denied:
            self.viewDelegate?.showAlert(self,
                                         title: NSLocalizedString("AlertTitle", comment: "Title for error alert"),
                                         message: NSLocalizedString("CameraReject", comment: "Description the alert"), showSettings: true)
        default:
            return
        }
    }
    
    func didTapEnabledMicrophoneButton() {
        let authorizationStatus = AVCaptureDevice.authorizationStatus(for: .audio)
        
        switch authorizationStatus {
        case .notDetermined:
            AVCaptureDevice.requestAccess(for: .audio) { [weak self] success in
                guard let self = self else { return }
                if success {
                    self.checkCameraAndMicAuthorization()
                    self.viewDelegate?.changeMicrophoneButton(self, authorizationStatus: .authorized)
                } else {
                    self.viewDelegate?.changeMicrophoneButton(self, authorizationStatus: .denied)
                }
            }
        case .denied:
            self.viewDelegate?.showAlert(self,
                                         title: NSLocalizedString("AlertTitle", comment: "Title for error alert"),
                                         message: NSLocalizedString("MicrophoneReject", comment: "Description the alert"), showSettings: true)
        default:
            return
        }
    }
    
    func didTapSwitchCameraTypeButton() {
        do {
            try cameraManager?.flipCaptureDevicePosition()
            if let isFrontCamera = cameraManager?.isFrontCamera() {
                viewDelegate?.showFlashlight(self, isFrontCamera: isFrontCamera)
            }
        } catch {
            print(error)
        }
    }
    
    func didTapFlashlightButton() {
        guard let cameraManager = cameraManager else { return }
        if cameraManager.toggleFlashlight(force: true) {
            viewDelegate?.didFlashlightChangeMode(self)
        }
    }
    
    func didTapRecordButton() {
        isRecording = !isRecording
        if isRecording {
            let uuidString = UUID().uuidString
            let documentDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
            let url = documentDirectory.appendingPathComponent("\(uuidString).mp4")
            
            guard let appDelegate = UIApplication.shared.delegate as? AppDelegate else { return }
            let context = appDelegate.persistentContainer.viewContext
            
            video = Video(context: context)
            video?.creationAt = Date()
            video?.url = url
            video?.id = uuidString
            
            do {
                try video?.managedObjectContext?.save()
            } catch {
                print("Failure to save context: \(error)")
            }
            
            videoWriter?.startRecording(to: url)
        } else {
            videoWriter?.stopRecording()
        }
    }
    
    private func checkCameraAndMicAuthorization() {
        if AVCaptureDevice.authorizationStatus(for: .video) == .authorized && AVCaptureDevice.authorizationStatus(for: .audio) == .authorized {
            viewDelegate?.cameraAndMicrophoneAccessGranted(self)
            do {
                try AVAudioSession.sharedInstance().setCategory(.playAndRecord)
                try AVAudioSession.sharedInstance().setActive(true, options: .notifyOthersOnDeactivation)
                try cameraManager?.start()
            } catch {
                print(error)
            }
        }
    }
    
    func switchOrientation(orientation: UIDeviceOrientation) {
        let cameramManagerOrientation = convertOrientation(orientation: orientation)
        cameraManager?.changeOrientation(orientation: cameramManagerOrientation)
        
        guard let previewLayer = cameraManager?.previewLayer else { return }
        viewDelegate?.didChangeCameraOrientation(self, previewLayer: previewLayer)
    }
    
    func convertOrientation(orientation: UIDeviceOrientation) -> AVCaptureVideoOrientation {
        switch orientation {
        case .landscapeLeft:
            return .landscapeRight
        case .landscapeRight:
            return .landscapeLeft
        case .portrait:
            return .portrait
        case .portraitUpsideDown:
            return .portraitUpsideDown
        default:
            return .portrait
        }
    }
    
    func applicationChangeState() {
        if cameraState == .working {
            cameraState = .interrupted
        }
    }
}

extension MainViewModel: CameraCaptureDelegate {
    func cameraCaptureDidStart(_ capture: CameraManager) {
        cameraState = .initialized
    }
    
    func cameraCaptureDidStop(_ capture: CameraManager) {
        cameraState = .stopped
    }
}

extension MainViewModel: VideoWriterDelegate {
    func didBeginWriting(_ videoWriter: VideoWriter) {
        viewDelegate?.didChangeRecordState(self, isRecording: isRecording)
        cameraState = .working
    }
    
    func videoWriter(_ videoWriter: VideoWriter, didStopWritingVideoTo url: URL) {
        viewDelegate?.didChangeRecordState(self, isRecording: isRecording)
        cameraState = .writing
    }
    
    func videoWriter(_ videoWriter: VideoWriter, didFailedWritingVideoWith error: Error) {
        print("VideoWriter Error: Error \(error)")
    }
}
