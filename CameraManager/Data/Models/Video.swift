//
//  Video.swift
//  CameraManager
//
//  Created by Moshkina on 16.09.2021.
//

import UIKit
import CoreData

class Video: NSManagedObject {
    
    @NSManaged var id: String?
    @NSManaged var creationAt: Date?
    @NSManaged var url: URL?
    @NSManaged var thumbnail: Data?
    
    init (id: String, creationAt: Date, url: URL, thumbnail: Data) {
        super.init()
        
        self.id = id
        self.creationAt = creationAt
        self.url = url
        self.thumbnail = thumbnail
    }
}
