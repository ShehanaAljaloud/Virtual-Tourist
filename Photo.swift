//
//  Photo.swift
//  VirtualTourist_
//
//  Created by Shehana Aljaloud on 22/06/2019.
//  Copyright © 2019 Shehana Aljaloud. All rights reserved.
//

import Foundation
import CoreData

@objc(Photo)
public class Photo: NSManagedObject {
    
}
extension Photo {
    
    @nonobjc public class func fetchRequest() -> NSFetchRequest<Photo> {
        return NSFetchRequest<Photo>(entityName: "Photo")
    }
    
    @NSManaged public var imageData: NSData?
    @NSManaged public var urlString: String?
    @NSManaged public var pin: Pin?
    
}
