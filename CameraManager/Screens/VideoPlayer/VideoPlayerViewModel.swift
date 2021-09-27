//
//  VideoPlayerViewModel.swift
//  CameraManager
//
//  Created by Moshkina on 24.09.2021.
//

import UIKit

class VideoPlayerViewModel {
    
    private var video: Video
    
    init(video: Video) {
        self.video = video
    }
    
    func getUrl() -> URL {
        return video.url ?? URL(fileURLWithPath: "")
    }
    
    func getTitle() -> String {
        return video.id ?? ""
    }
    
    func getCreationTime() -> String {
        var creationAtString: String?
        if let creationAt = video.creationAt {
            let dateFormatter = DateFormatter()
            dateFormatter.dateFormat = "dd-mm-yy hh:MM:ss"
            creationAtString = dateFormatter.string(from: creationAt)
        }
        return creationAtString ?? ""
    }
}
