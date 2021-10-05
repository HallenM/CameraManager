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
        if let lastPathComponent = video.url?.lastPathComponent {
            return FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!.appendingPathComponent(lastPathComponent)
        }
        return video.url ?? URL(fileURLWithPath: "")
    }
    
    func getTitle() -> String {
        if let title = video.id {
        return "Title: " + title
        } else {
            return ""
        }
    }
    
    func getCreationTime() -> String {
        var creationAtString: String?
        if let creationAt = video.creationAt {
            let dateFormatter = DateFormatter()
            dateFormatter.dateFormat = "dd-MM-yy HH:mm:ss"
            creationAtString = dateFormatter.string(from: creationAt)
        }
        
        if let creationAtString = creationAtString {
            return "Created at: " + creationAtString
        } else {
            return ""
        }
    }
}
