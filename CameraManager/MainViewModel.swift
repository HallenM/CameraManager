//
//  MainViewModel.swift
//  CameraManager
//
//  Created by Moshkina on 06.09.2021.
//

import UIKit
import AVFoundation

protocol ViewModelProtocol: AnyObject {
    var viewDelegate: ViewModelDisplayDelegate? { get set }
    var previewLayer: AVCaptureVideoPreviewLayer? { get }
    
    func didTapEnabledCameraButton()
    func didTapEnabledMicrophoneButton()
    func didTapSwitchCameraTypeButton()
    func switchOrientation(orientation: UIDeviceOrientation)
}

protocol ViewModelDisplayDelegate: AnyObject {
    func changeCameraButton(_ sender: ViewModelProtocol, authorizationStatus: AVAuthorizationStatus)
    func changeMicrophoneButton(_ sender: ViewModelProtocol, authorizationStatus: AVAuthorizationStatus)
    func cameraAndMicrophoneAccessGranted(_ sender: ViewModelProtocol)
    func showAlert(_ sender: ViewModelProtocol, title: String, message: String)
    func showPreview(_ sender: ViewModelProtocol, previewLayer: AVCaptureVideoPreviewLayer)
    func didChangeCameraOrientation(_ sender: ViewModelProtocol, previewLayer: AVCaptureVideoPreviewLayer)
}

class MainViewModel {
    var viewDelegate: ViewModelDisplayDelegate?
    var cameraManager: CameraManager?
    
    var previewLayer: AVCaptureVideoPreviewLayer? {
        return cameraManager?.previewLayer
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
    }
}

extension  MainViewModel: ViewModelProtocol {
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
                                         message: NSLocalizedString("CameraReject", comment: "Description the alert"))
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
                                         message: NSLocalizedString("MicrophoneReject", comment: "Description the alert"))
        default:
            return
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
    
    func didTapSwitchCameraTypeButton() {
        do {
            try cameraManager?.flipCaptureDevicePosition()
        } catch {
            print(error)
        }
    }
    
    func switchOrientation(orientation: UIDeviceOrientation) {
        switch orientation {
        case .landscapeLeft:
            cameraManager?.previewLayer.connection?.videoOrientation = .landscapeRight
        case .landscapeRight:
            cameraManager?.previewLayer.connection?.videoOrientation = .landscapeLeft
        case .portrait:
            cameraManager?.previewLayer.connection?.videoOrientation = .portrait
        case .portraitUpsideDown:
            cameraManager?.previewLayer.connection?.videoOrientation = .portraitUpsideDown
        default:
            return
        }
        
        guard let previewLayer = cameraManager?.previewLayer else { return }
        viewDelegate?.didChangeCameraOrientation(self, previewLayer: previewLayer)
    }
}

extension MainViewModel: CameraCaptureDelegate {
    func cameraCaptureDidStart(_ capture: CameraManager) {
        viewDelegate?.showPreview(self, previewLayer: capture.previewLayer)
    }
    
    func cameraCaptureDidStop(_ capture: CameraManager) {
        
    }
}
