//
//  ThumbnailGenerator.swift
//  CameraManager
//
//  Created by Moshkina on 21.09.2021.
//

import UIKit
import AVFoundation

class ThumbnailGenerator {
    
    static func generateThumbnail(for url: URL) -> UIImage? {
        do {
            let asset = AVURLAsset(url: url, options: nil)
            let imgGenerator = AVAssetImageGenerator(asset: asset)
            imgGenerator.appliesPreferredTrackTransform = true
            let cgImage = try imgGenerator.copyCGImage(at: CMTimeMake(value: 0, timescale: 1), actualTime: nil)
            let thumbnail = UIImage(cgImage: cgImage)
            return thumbnail
        } catch let error {
            print("*** Error generating thumbnail: \(error.localizedDescription)")
            return nil
        }
    }
}
