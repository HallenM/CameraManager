//
//  ViewController.swift
//  CameraManager
//
//  Created by Moshkina on 06.09.2021.
//

import UIKit
import AVFoundation

class ViewController: UIViewController {
    
    @IBOutlet private weak var stackView: UIStackView!
    @IBOutlet private weak var enabledCameraButton: UIButton!
    @IBOutlet private weak var enabledMicrophoneButton: UIButton!
    
    private var viewModel: ViewModelProtocol? = MainViewModel()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        viewModel?.viewDelegate = self
        
        let cameraAuthorizationStatus = AVCaptureDevice.authorizationStatus(for: .video)
        let microphoneAuthorizationStatus = AVCaptureDevice.authorizationStatus(for: .audio)
        
        if cameraAuthorizationStatus == .authorized && microphoneAuthorizationStatus == .authorized {
            stackView.isHidden = true
        } else {
            stackView.isHidden = false
            
            setButtonState(button: enabledCameraButton, authorizationStatus: cameraAuthorizationStatus)
            setButtonState(button: enabledMicrophoneButton, authorizationStatus: microphoneAuthorizationStatus)
        }
        
    }
    
    private func setButtonState(button: UIButton, authorizationStatus: AVAuthorizationStatus) {
        if authorizationStatus == .denied {
            button.backgroundColor = .systemRed
        } else if authorizationStatus == .authorized {
            button.backgroundColor = .systemGreen
            button.isEnabled = false
        }
    }
    
    private func createAlert(title: String, message: String) -> UIAlertController {
        let alertController = UIAlertController(title: title, message: message, preferredStyle: .alert)
        
        let settingsAction = UIAlertAction(title: "Settings", style: .default) { (_) -> Void in
            guard let settingsUrl = URL(string: UIApplication.openSettingsURLString) else { return }
            
            UIApplication.shared.canOpenURL(settingsUrl)
            UIApplication.shared.open(settingsUrl, options: [:])
        }
        alertController.addAction(settingsAction)
        
        let cancelAction = UIAlertAction(title: "Cancel", style: .default, handler: nil)
        alertController.addAction(cancelAction)
        
        return alertController
    }
    
    @IBAction private func didTapEnabledCameraButton(_ sender: UIButton) {
        viewModel?.didTapEnabledCameraButton()
    }

    @IBAction private func didTapEnabledMicrophoneButton(_ sender: UIButton) {
        viewModel?.didTapEnabledMicrophoneButton()
    }
}

extension ViewController: ViewModelDisplayDelegate {
    func showAlert(_ sender: ViewModelProtocol, title: String, message: String) {
        DispatchQueue.main.async {
            let alertController = self.createAlert(title: title, message: message)
            self.present(alertController, animated: true, completion: nil)
        }
    }
    
    func changeCameraButton(_ sender: ViewModelProtocol, authorizationStatus: AVAuthorizationStatus) {
        DispatchQueue.main.async {
            self.setButtonState(button: self.enabledCameraButton, authorizationStatus: authorizationStatus)
        }
    }
    
    func changeMicrophoneButton(_ sender: ViewModelProtocol, authorizationStatus: AVAuthorizationStatus) {
        DispatchQueue.main.async {
            self.setButtonState(button: self.enabledMicrophoneButton, authorizationStatus: authorizationStatus)
        }
    }
    
    func cameraAndMicrophoneAccessGranted(_ sender: ViewModelProtocol) {
        DispatchQueue.main.async {
            self.stackView.isHidden = true
        }
    }
}
