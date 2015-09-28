//
//  LocationsViewController.swift
//  VirtualTourist
//
//  Created by Victor Guerra on 04/08/15.
//  Copyright (c) 2015 Victor Guerra. All rights reserved.
//

import UIKit
import MapKit
import CoreData

class LocationsViewController : UIViewController, NSFetchedResultsControllerDelegate {


    @IBOutlet weak var locationsMap: MKMapView!
    @IBOutlet weak var deletePinsLabel: UILabel!
    
    var pinToSave : Pin? = nil
    var editMode : Bool = false
    
    var filePath : String {
        let manager = NSFileManager.defaultManager()
        let url : NSURL = manager.URLsForDirectory(.DocumentDirectory, inDomains: .UserDomainMask).first!
        return url.URLByAppendingPathComponent("mapRegionArchive").path!
    }
    
    lazy var fetchedResultsController : NSFetchedResultsController = {
        let fetchRequest = NSFetchRequest(entityName: "Pin")
        fetchRequest.sortDescriptors = [NSSortDescriptor(key: "creationDate", ascending: true)]
        return NSFetchedResultsController(fetchRequest: fetchRequest, managedObjectContext: self.sharedContext, sectionNameKeyPath: nil, cacheName: nil)
    }()
    
    // MARK: Core Data Convenience.

    var sharedContext : NSManagedObjectContext {
        return CoreDataStackManager.sharedInstance.managedObjectContext!
    }

    
    // MARK: View Controller Life Cycle
    
    override func viewDidLoad() {

        super.viewDidLoad()
        
        self.navigationItem.rightBarButtonItem = self.editButtonItem()
        self.navigationItem.title = "Virtual Tourist"
        
        self.navigationItem.backBarButtonItem = UIBarButtonItem(title:"OK", style:.Plain, target:nil, action:nil)
        
        // MapView configuration
        let longPressOnMapGesture = UILongPressGestureRecognizer(target: self,
            action: "handleLongPressOnMap:")
        longPressOnMapGesture.minimumPressDuration = 1.5
        locationsMap.delegate = self
        locationsMap.addGestureRecognizer(longPressOnMapGesture)
        restoreMapRegion(false)

        do {
            try fetchedResultsController.performFetch()
        } catch _ {
            
        }
        
        fetchedResultsController.delegate = self

        populateMap()
        
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
    }

    override func setEditing(editing: Bool, animated: Bool) {
        super.setEditing(editing, animated: animated)
        self.editMode = editing
        toggleDeletePinsLabel(editing, animated: animated)
    }

    
    // MARK: Populating map
    
    func populateMap() {
        if let pins = fetchedResultsController.fetchedObjects as? [Pin] {
            locationsMap.addAnnotations(pins)
        }
    }
    
    // MARK: Delete pins Label animations
    
    func toggleDeletePinsLabel(editing: Bool, animated: Bool) {
        let hideShowFactor : CGFloat = editing ? -1.0 : 1.0
        let animationDuration : NSTimeInterval = animated ? 0.5 : 0.0
        
        UIView.animateWithDuration(animationDuration) {
            let labelHeight = self.deletePinsLabel.frame.height
//            self.deletePinsLabel.frame = CGRectOffset(self.deletePinsLabel.frame, 0.0, hideShowFactor*labelHeight)
            self.locationsMap.frame.size.height += hideShowFactor*labelHeight
        }
    }
    
    // MARK: Persistance for the map region

    func saveMapRegion() {
        let dictionary = [
            "latitude" : locationsMap.region.center.latitude,
            "longitude" : locationsMap.region.center.longitude,
            "latitudeDelta" : locationsMap.region.span.latitudeDelta,
            "longitudeDelta" : locationsMap.region.span.longitudeDelta
        ]
        
        NSKeyedArchiver.archiveRootObject(dictionary, toFile: filePath)
    }
    
    func restoreMapRegion(animated: Bool) {
        
        // if we can unarchive a dictionary, we will use it to set the map back to its
        // previous center and span
        if let regionDictionary = NSKeyedUnarchiver.unarchiveObjectWithFile(filePath) as? [String : AnyObject] {
            
            let longitude = regionDictionary["longitude"] as! CLLocationDegrees
            let latitude = regionDictionary["latitude"] as! CLLocationDegrees
            let center = CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
            
            let longitudeDelta = regionDictionary["latitudeDelta"] as! CLLocationDegrees
            let latitudeDelta = regionDictionary["longitudeDelta"] as! CLLocationDegrees
            let span = MKCoordinateSpan(latitudeDelta: latitudeDelta, longitudeDelta: longitudeDelta)
            
            let savedRegion = MKCoordinateRegion(center: center, span: span)
            
            locationsMap.setRegion(savedRegion, animated: animated)
        }
    }
    
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        if segue.identifier == "showPhotoAlbum" {
            let photoAlbumVC = segue.destinationViewController as! PhotoAlbumViewController
            let data : Pin = sender as! Pin
            photoAlbumVC.pin = data
        }
    }
    
}



// MARK: Conforming to MKMapViewDelegate and handling of gestures

extension LocationsViewController : MKMapViewDelegate {

    func handleLongPressOnMap(gestureRecognizer : UIGestureRecognizer){
        let touchPoint = gestureRecognizer.locationInView(self.locationsMap)
        let touchMapCoordinate = self.locationsMap.convertPoint(touchPoint,
            toCoordinateFromView: self.locationsMap)
        switch gestureRecognizer.state {
        case .Began :
            let pinInfo = [Pin.Keys.Latitude : touchMapCoordinate.latitude,
                Pin.Keys.Longitude : touchMapCoordinate.longitude]
            
            pinToSave = Pin(dictionary: pinInfo, context: sharedContext)
            locationsMap.addAnnotation(pinToSave!)

        case .Changed :
            pinToSave!.coordinate = touchMapCoordinate
            
        case .Ended :
            CoreDataStackManager.sharedInstance.saveContext()
            
        default:
            break
        }
    }
    
    func mapView(mapView: MKMapView, didDeselectAnnotationView view: MKAnnotationView) {
        let pinSelected = view.annotation as! Pin
        if editMode {
            locationsMap.removeAnnotation(pinSelected)
            sharedContext.deleteObject(pinSelected)
            CoreDataStackManager.sharedInstance.saveContext()
        } else {
            self.performSegueWithIdentifier("showPhotoAlbum", sender: pinSelected)
        }
    }

    func mapView(mapView: MKMapView, viewForAnnotation annotation: MKAnnotation) -> MKAnnotationView? {
        let reuseId = "pin"
        var pinView = mapView.dequeueReusableAnnotationViewWithIdentifier(reuseId) as? MKPinAnnotationView
        if pinView == nil {
            pinView = MKPinAnnotationView(annotation: annotation, reuseIdentifier: reuseId)
            pinView!.pinColor = .Red
            pinView!.animatesDrop = true
        } else {
            pinView!.annotation = annotation
        }
        return pinView
    }
    
    // Making changes of region on Map persistant
    func mapView(mapView: MKMapView, regionDidChangeAnimated animated: Bool) {
        saveMapRegion()
    }
    
    
    // MARK: Conforming NSFetchedResultsControllerDelegate
    // IS THIS REALLY NEEDED???!!!
    
//    func controller(controller: NSFetchedResultsController, didChangeObject anObject: AnyObject, atIndexPath indexPath: NSIndexPath?, forChangeType type: NSFetchedResultsChangeType, newIndexPath: NSIndexPath?) {
//        
//        switch type  {
//        case .Insert:
//            print("we inserted an object")
//        case .Update:
//            print("we updated an object")
//        case .Move:
//            print("we moved an object")
//        case .Delete:
//            print("Getting message that we deleted an object")
//            locationsMap.removeAnnotation(anObject as! Pin)
//        }
//    }
}