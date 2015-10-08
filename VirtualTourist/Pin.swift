//
//  Pin.swift
//  VirtualTourist
//
//  Created by Victor Guerra on 01/09/15.
//  Copyright (c) 2015 Victor Guerra. All rights reserved.
//

import UIKit
import CoreData
import MapKit

//Pin class represents an annotation done by the user
//in the map. It has associated an album of pictures, (15)
//by default, that will be downloaded from the internet.

class Pin : NSManagedObject, MKAnnotation {

    struct Keys {
        static let Latitude = "Latitude"
        static let Longitude = "Longitude"
        static let CreationDate = "CreationDate"
    }
    
    @NSManaged var latitude : Double
    @NSManaged var longitude : Double
    @NSManaged var creationDate : NSDate
    @NSManaged var photos : [Photo]
    
    dynamic var coordinate : CLLocationCoordinate2D {
        get {
            return CLLocationCoordinate2D(latitude: CLLocationDegrees(latitude),
                longitude: CLLocationDegrees(longitude))
        }
        set(newCoordinate)  {
            latitude = newCoordinate.latitude
            longitude = newCoordinate.longitude
        }
    }
    
    override init(entity: NSEntityDescription, insertIntoManagedObjectContext context: NSManagedObjectContext?) {
        super.init(entity: entity, insertIntoManagedObjectContext: context)
    }
    
    init(dictionary : [String : AnyObject], context: NSManagedObjectContext) {
        let entity = NSEntityDescription.entityForName("Pin", inManagedObjectContext: context)!
        super.init(entity: entity, insertIntoManagedObjectContext: context)

        latitude = dictionary[Keys.Latitude] as! Double
        longitude = dictionary[Keys.Longitude] as! Double
        creationDate = NSDate()
    }
    
}