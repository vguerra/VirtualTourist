//
//  Photo.swift
//  VirtualTourist
//
//  Created by Victor Guerra on 01/09/15.
//  Copyright (c) 2015 Victor Guerra. All rights reserved.
//

import UIKit
import CoreData

class Photo : NSManagedObject {
    
    struct Keys {
        static let PhotoId = "photoId"
        static let PhotoTitle = "photoTitle"
        static let PhotoURL = "photoURL"
    }
    
    @NSManaged var photoId : String?
    @NSManaged var photoTitle : String?
    @NSManaged var photoURL : String?
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
    }
    
    override func prepareForDeletion() {
        super.prepareForDeletion()
        do {
            try NSFileManager().removeItemAtPath(photoPathInFS)
        } catch let er as NSError {
            print("there was an error deleting associated Photo file: \(er)")
        }
    }
    
    lazy var photoPathInFS : String = {
        let documentsDirectory = CoreDataStackManager.sharedInstance.applicationDocumentsDirectory
        return documentsDirectory.URLByAppendingPathComponent("\(self.photoId!).jpg").path!
    }()
    
    var image : UIImage? {
        get {
            return UIImage(contentsOfFile: photoPathInFS)
        }
        set {
            guard UIImageJPEGRepresentation(newValue!, 1.0)!.writeToFile(photoPathInFS, atomically: false) else {
                print("saving Photo file in \(photoPathInFS) went wrong")
                return
            }
        }
    }
}
