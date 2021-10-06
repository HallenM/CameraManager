//
//  VideoProcessor.swift
//  CameraManager
//
//  Created by Moshkina on 30.09.2021.
//

import AVFoundation
import UIKit

class VideoProcessor {
    
    func modifiedBuffer(imageBuffer: CVImageBuffer, videoProcessorTimerText: String, videoProcessorTextColor: UIColor) -> CVImageBuffer? {
        let ciImage = CIImage(cvImageBuffer: imageBuffer)
        let frameImage = UIImage(ciImage: ciImage)
        let ciContext = CIContext()
        
        let timerString = NSAttributedString(string: videoProcessorTimerText,
                                        attributes: [NSAttributedString.Key.foregroundColor: videoProcessorTextColor,
                                                     NSAttributedString.Key.font: UIFont.systemFont(ofSize: 17.0)])
        
        guard let timerCIImage = createImage(from: timerString) else { return nil }
        let timerImage = UIImage(ciImage: timerCIImage)
        
        let resultImage = drawLogoIn(image: frameImage, logo: timerImage, position: CGPoint(x: frameImage.size.width/10, y: frameImage.size.height - frameImage.size.height/10))
        
        guard let resultCIImage = CIImage(image: resultImage) else { return nil }
        
        var pixelBuffer: CVPixelBuffer?
        let attrs = [kCVPixelBufferCGImageCompatibilityKey: kCFBooleanTrue, kCVPixelBufferCGBitmapContextCompatibilityKey: kCFBooleanTrue] as CFDictionary
        CVPixelBufferCreate(kCFAllocatorDefault, Int(resultCIImage.extent.width), Int(resultCIImage.extent.height), kCVPixelFormatType_32ARGB, attrs, &pixelBuffer)
        
        if let buffer = pixelBuffer {
            ciContext.render(resultCIImage, to: buffer)
            return pixelBuffer
        }
        
        return nil
    }
    
    private func createImage(from string: NSAttributedString) -> CIImage? {
        let stringSize = string.size()
        let screenRect = UIScreen.main.bounds
        let contextSize = CGSize(width: screenRect.size.width - screenRect.size.width/4, height: stringSize.height + 10)
        
        UIGraphicsBeginImageContext(contextSize)
        let rect = CGRect(origin: CGPoint(x: screenRect.size.width/2 - stringSize.width, y: 5), size: stringSize)
        let rect2 = CGRect(origin: CGPoint(x: 0, y: 0), size: contextSize)
        
        let context = UIGraphicsGetCurrentContext()
        context?.setFillColor(CGColor(srgbRed: 142, green: 142, blue: 147, alpha: 0.4))
        context?.addRect(rect2)
        context?.fill(rect2)
        
        string.draw(in: rect)
        let image = UIGraphicsGetImageFromCurrentImageContext()
        
        UIGraphicsEndImageContext()
        
        guard let uiImage = image else {
            return nil
        }
        return CIImage(image: uiImage)
    }
    
    private func drawLogoIn(image: UIImage, logo: UIImage, position: CGPoint) -> UIImage {
        let renderer = UIGraphicsImageRenderer(size: image.size)
        let logoSize = CGSize(width: image.size.width - image.size.width/8, height: image.size.height/15)
        
        return renderer.image { context in
            image.draw(in: CGRect(origin: CGPoint.zero, size: image.size))
            logo.draw(in: CGRect(origin: position, size: logoSize))
        }
    }
}
