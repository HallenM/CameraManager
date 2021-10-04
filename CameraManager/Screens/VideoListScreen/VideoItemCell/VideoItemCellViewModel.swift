//
//  VideoItemCellViewModel.swift
//  CameraManager
//
//  Created by Moshkina on 23.09.2021.
//

import UIKit

class VideoItemCellViewModel {
    
    var thumbnail: UIImage?
    var title: String?
    
    var videoData: Video
    
    init(video: Video) {
        self.videoData = video
        
        if let thumbnailImage = video.thumbnail,
           let creationAt = video.creationAt {
            thumbnail = UIImage().toImage(data: thumbnailImage)
            
            let dateFormatter = DateFormatter()
            dateFormatter.dateFormat = "dd-MM-yy HH:mm:ss"
            title = dateFormatter.string(from: creationAt)
        }
    }
}
