//
//  MainViewModel.swift
//  CameraManager
//
//  Created by Moshkina on 06.09.2021.
//

import Foundation
import AVFoundation

protocol ViewModelProtocol: AnyObject {
    var viewDelegate: ViewModelDisplayDelegate? { get set }
    
    func didTapEnabledCameraButton()
    func didTapEnabledMicrophoneButton()
}

protocol ViewModelDisplayDelegate: AnyObject {
    func changeCameraButton(_ sender: ViewModelProtocol, authorizationStatus: AVAuthorizationStatus)
    func changeMicrophoneButton(_ sender: ViewModelProtocol, authorizationStatus: AVAuthorizationStatus)
    func cameraAndMicrophoneAccessGranted(_ sender: ViewModelProtocol)
    func showAlert(_ sender: ViewModelProtocol, title: String, message: String)
}

class MainViewModel {
    var viewDelegate: ViewModelDisplayDelegate?
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
            self.viewDelegate?.showAlert(self, title: "Error", message: "You rejected camera permission. Go to settings for changing it.")
        default:
            return
        }
    }
    
    func didTapEnabledMicrophoneButton() {
        let authorizationStatus = AVCaptureDevice.authorizationStatus(for: .audio)
        
        if authorizationStatus == .notDetermined {
            AVCaptureDevice.requestAccess(for: .audio) { [weak self] success in
                guard let self = self else { return }
                if success {
                    self.checkCameraAndMicAuthorization()
                    self.viewDelegate?.changeMicrophoneButton(self, authorizationStatus: .authorized)
                } else {
                    self.viewDelegate?.changeMicrophoneButton(self, authorizationStatus: .denied)
                }
            }
        } else if authorizationStatus == .denied {
            self.viewDelegate?.showAlert(self, title: "Error", message: "You rejected microphone permission. Go to settings for changing it.")
        }
    }
    
    private func checkCameraAndMicAuthorization() {
        if AVCaptureDevice.authorizationStatus(for: .video) == .authorized && AVCaptureDevice.authorizationStatus(for: .audio) == .authorized {
            viewDelegate?.cameraAndMicrophoneAccessGranted(self)
        }
    }
}
