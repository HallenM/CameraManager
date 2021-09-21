//
//  UIImage.swift
//  CameraManager
//
//  Created by Moshkina on 21.09.2021.
//

import UIKit

extension UIImage {
    func toData () -> Data? {
        return self.pngData()
    }
    
    func toImage (data: Data) -> UIImage? {
        return UIImage(data: data)
    }
}
