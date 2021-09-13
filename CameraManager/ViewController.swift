//
//  ViewController.swift
//  CameraManager
//
//  Created by Moshkina on 06.09.2021.
//

import UIKit
import AVFoundation

class ViewController: UIViewController {
    
    @IBOutlet private weak var previewView: UIView!
    @IBOutlet private weak var stackView: UIStackView!
    
    @IBOutlet private weak var enabledCameraButton: UIButton!
    @IBOutlet private weak var enabledMicrophoneButton: UIButton!
    
    @IBOutlet private weak var switchCameraTypeButton: UIButton!
    @IBOutlet private weak var flashlightButton: UIButton!
    @IBOutlet private weak var recordButton: UIButton!
    
    private var viewModel: ViewModelProtocol?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        viewModel = MainViewModel()
        viewModel?.viewDelegate = self
        
        enabledCameraButton.setTitle(NSLocalizedString("EnabledCameraButton", comment: "Title for enable camera permission button"), for: .normal)
        enabledMicrophoneButton.setTitle(NSLocalizedString("EnabledMicrophoneButton", comment: "Title for enable microphone permission button"), for: .normal)
        
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
    
    override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        super.viewWillTransition(to: size, with: coordinator)
        let orientation = UIDevice.current.orientation
        
        coordinator.animate { _ in
            DispatchQueue.main.async {
                self.viewModel?.previewLayer?.removeAllAnimations()
                self.viewModel?.switchOrientation(orientation: orientation)
            }
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
        
        let settingsAction = UIAlertAction(title: NSLocalizedString("Settings", comment: "Title for alert button settings"), style: .default) { (_) -> Void in
            guard let settingsUrl = URL(string: UIApplication.openSettingsURLString) else { return }
            
            UIApplication.shared.canOpenURL(settingsUrl)
            UIApplication.shared.open(settingsUrl, options: [:])
        }
        alertController.addAction(settingsAction)
        
        let cancelAction = UIAlertAction(title: NSLocalizedString("Cancel", comment: "Title for alert button cancel"), style: .default, handler: nil)
        alertController.addAction(cancelAction)
        
        return alertController
    }
    
// MARK: IBActions
    @IBAction private func didTapEnabledCameraButton(_ sender: UIButton) {
        viewModel?.didTapEnabledCameraButton()
    }

    @IBAction private func didTapEnabledMicrophoneButton(_ sender: UIButton) {
        viewModel?.didTapEnabledMicrophoneButton()
    }
    
    @IBAction private func didTapSwitchCameraTypeButton(_ sender: UIButton) {
        viewModel?.didTapSwitchCameraTypeButton()
    }
    
    @IBAction private func didTapFlashlightButton(_ sender: UIButton) {
        viewModel?.didTapFlashlightButton()
    }
    
    @IBAction private func didTapRecordButton(_ sender: UIButton) {
    }
}

// MARK: Extensions
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
    
    func showPreview(_ sender: ViewModelProtocol, previewLayer: AVCaptureVideoPreviewLayer) {
        previewLayer.frame = previewView.layer.bounds
        previewView.layer.addSublayer(previewLayer)
        
        switchCameraTypeButton.isHidden = false
        recordButton.isHidden = false
    }
    
    func showFlashlight(_ sender: ViewModelProtocol, isFrontCamera: Bool) {
        if isFrontCamera {
            flashlightButton.isHidden = true
        } else {
            flashlightButton.isHidden = false
        }
    }
    
    func changeFlashlightButtonColor(_ sender: ViewModelProtocol) {
        let color = flashlightButton.tintColor
        if color == UIColor(named: "flashOn") {
            flashlightButton.tintColor = UIColor(named: "flashOff")
        } else {
            flashlightButton.tintColor = UIColor(named: "flashOn")
        }
    }
    
    func didChangeCameraOrientation(_ sender: ViewModelProtocol, previewLayer: AVCaptureVideoPreviewLayer) {
        previewLayer.frame = previewView.layer.bounds
    }
}
