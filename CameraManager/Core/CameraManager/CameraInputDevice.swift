//
//  CameraInputDevice.swift
//  CameraManager
//
//  Created by Moshkina on 09.09.2021.
//

import AVFoundation

class CameraInputDevice {
    class func availableDevices(position: AVCaptureDevice.Position) -> [AVCaptureDevice] {
        return AVCaptureDevice.DiscoverySession(deviceTypes: [.builtInWideAngleCamera, .builtInTelephotoCamera],
                                                mediaType: .video,
                                                position: position).devices
    }
}
