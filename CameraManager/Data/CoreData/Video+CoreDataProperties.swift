//
//  Video+CoreDataProperties.swift
//  CameraManager
//
//  Created by Moshkina on 21.09.2021.
//
//

import Foundation
import CoreData

extension Video {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<Video> {
        return NSFetchRequest<Video>(entityName: "Video")
    }

    @NSManaged public var creationAt: Date?
    @NSManaged public var id: String?
    @NSManaged public var thumbnail: Data?
    @NSManaged public var url: URL?

}

extension Video : Identifiable {

}
