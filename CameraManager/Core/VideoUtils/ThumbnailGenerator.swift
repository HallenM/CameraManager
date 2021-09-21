//
//  ThumbnailGenerator.swift
//  CameraManager
//
//  Created by Moshkina on 21.09.2021.
//

import UIKit
import AVFoundation

class ThumbnailGenerator {
    
    static let shared = ThumbnailGenerator()
    
    var thumbnailImage: UIImage?
    
    func generateThumbnailRepresentations(url: URL, completion: @escaping (_ isSuccess: Bool) -> Void) {
        do {
            let asset = AVURLAsset(url: url, options: nil)
            let imgGenerator = AVAssetImageGenerator(asset: asset)
            imgGenerator.appliesPreferredTrackTransform = true
            let cgImage = try imgGenerator.copyCGImage(at: CMTimeMake(value: 0, timescale: 1), actualTime: nil)
            let thumbnail = UIImage(cgImage: cgImage)
            self.thumbnailImage = thumbnail
            completion(true)
        } catch let error {
            print("*** Error generating thumbnail: \(error.localizedDescription)")
            completion(false)
        }
    }
}
