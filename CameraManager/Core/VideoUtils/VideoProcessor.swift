//
//  VideoProcessor.swift
//  CameraManager
//
//  Created by Moshkina on 30.09.2021.
//

import AVFoundation
import UIKit

class VideoProcessor {
    
    func modifiedBuffer(imageBuffer: CVPixelBuffer, videoProcessorTimerText: String, videoProcessorTextColor: UIColor) -> CVImageBuffer? {
        let ciImage = CIImage(cvPixelBuffer: imageBuffer)
        
        let context = CIContext()
        
        let imageRect = CGRect(x: 0, y: 0, width: ciImage.extent.width, height: ciImage.extent.height)
        let timerRect = CGRect(x: 10, y: 10, width: 80, height: 80)
        
        // нужно срендерить картинку из строки а потом её на фрейм наложить

        context.draw(ciImage, in: imageRect, from: timerRect)
        
        var pixelBuffer: CVPixelBuffer?
        let attrs = [kCVPixelBufferCGImageCompatibilityKey: kCFBooleanTrue, kCVPixelBufferCGBitmapContextCompatibilityKey: kCFBooleanTrue] as CFDictionary
        CVPixelBufferCreate(kCFAllocatorDefault, Int(ciImage.extent.width), Int(ciImage.extent.height), kCVPixelFormatType_32ARGB, attrs, &pixelBuffer)
        
        if let buffer = pixelBuffer {
            context.render(ciImage, to: buffer)
            return pixelBuffer
        }
        
        return nil
    }
}
