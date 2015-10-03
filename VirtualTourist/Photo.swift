//
//  Photo.swift
//  VirtualTourist
//
//  Created by Victor Guerra on 01/09/15.
//  Copyright (c) 2015 Victor Guerra. All rights reserved.
//

import UIKit
import CoreData

// TODO: Move to somewhere else

func documentsDirectory() -> String {
    return NSSearchPathForDirectoriesInDomains(.DocumentDirectory, .UserDomainMask, true)[0]
}

func filePathInDocumentsDirectory(filename: String) -> String {
    return documentsDirectory().stringByAppendingString(filename + ".jpg")
}

class Photo : NSManagedObject {
    
    struct Keys {
        static let PhotoId = "photoId"
        static let PhotoTitle = "photoTitle"
        static let PhotoURL = "photoURL"
    }
    
    @NSManaged var photoId : String?
    @NSManaged var photoTitle : String?
    @NSManaged var photoURL : String?
    @NSManaged var photoPathInFS : String?
    @NSManaged var pin : Pin?
    
    override init(entity: NSEntityDescription, insertIntoManagedObjectContext context: NSManagedObjectContext?) {
        super.init(entity: entity, insertIntoManagedObjectContext: context)
    }
    
    
    init (dictionary : [String : AnyObject], context : NSManagedObjectContext) {
        let entity = NSEntityDescription.entityForName("Photo", inManagedObjectContext: context)!
        super.init(entity: entity, insertIntoManagedObjectContext: context)
        
        photoId = dictionary[Keys.PhotoId] as? String
        photoTitle = dictionary[Keys.PhotoTitle] as? String
        photoURL = dictionary[Keys.PhotoURL] as? String
        photoPathInFS = filePathInDocumentsDirectory(self.photoId!)
    }
    
    override func prepareForDeletion() {
        super.prepareForDeletion()
        do {
            try NSFileManager().removeItemAtPath(photoPathInFS!)
        } catch let er as NSError {
            print("there was an error deleting file: \(er)")
        }
    }
    
    var image : UIImage? {
        get {
            return UIImage(contentsOfFile: photoPathInFS!)
        }
        set {
            UIImageJPEGRepresentation(newValue!, 1.0)?.writeToFile(photoPathInFS!, atomically: true)
        }
    }
}
