//
//  ViewModelProtocols.swift
//  CameraManager
//
//  Created by Moshkina on 16.09.2021.
//

import AVFoundation
import UIKit

protocol ViewModelProtocol: AnyObject {
    var viewDelegate: ViewModelDisplayDelegate? { get set }
    var previewLayer: AVCaptureVideoPreviewLayer? { get }
    var timerDataString: String { get set }
    
    func didTapEnabledCameraButton()
    func didTapEnabledMicrophoneButton()
    func didTapSwitchCameraTypeButton()
    func didTapFlashlightButton()
    func didTapRecordButton()
    
    func switchOrientation(orientation: UIDeviceOrientation)
    func applicationChangeState()
}

protocol ViewModelDisplayDelegate: AnyObject {
    func changeCameraButton(_ sender: ViewModelProtocol, authorizationStatus: AVAuthorizationStatus)
    func changeMicrophoneButton(_ sender: ViewModelProtocol, authorizationStatus: AVAuthorizationStatus)
    func cameraAndMicrophoneAccessGranted(_ sender: ViewModelProtocol)

    func showAlert(_ sender: ViewModelProtocol, title: String, message: String, showSettings: Bool)    
    func showPreview(_ sender: ViewModelProtocol, previewLayer: AVCaptureVideoPreviewLayer)
    func showFlashlight(_ sender: ViewModelProtocol, isFrontCamera: Bool)
    func showVideo(_ sender: ViewModelProtocol, url: URL)
    func showTimer(_ sender: ViewModelProtocol, isRecording: Bool)
    func updateTimer(_ sender: ViewModelProtocol, timerData: String)
    
    func didChangeCameraOrientation(_ sender: ViewModelProtocol, previewLayer: AVCaptureVideoPreviewLayer)
    func didFlashlightChangeMode(_ sender: ViewModelProtocol)
    func didChangeRecordState(_ sender: ViewModelProtocol, isRecording: Bool)
}
