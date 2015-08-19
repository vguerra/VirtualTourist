//
//  LocationsViewController.swift
//  VirtualTourist
//
//  Created by Victor Guerra on 04/08/15.
//  Copyright (c) 2015 Victor Guerra. All rights reserved.
//

import UIKit
import MapKit

class LocationsViewController : UIViewController, MKMapViewDelegate {


    @IBOutlet weak var locationsMap: MKMapView!

    var movingAnnotation : MKPointAnnotation? = nil
    var editMode : Bool = false
    
    var filePath : String {
        let manager = NSFileManager.defaultManager()
        let url = manager.URLsForDirectory(.DocumentDirectory, inDomains: .UserDomainMask).first as! NSURL
        return url.URLByAppendingPathComponent("mapRegionArchive").path!
    }
    
    override func viewDidLoad() {
        
        self.navigationItem.rightBarButtonItem = self.editButtonItem()
        
        // MapView configuration
        var longPressOnMapGesture = UILongPressGestureRecognizer(target: self,
            action: "handleLongPressOnMap:")
        longPressOnMapGesture.minimumPressDuration = 1.5
        locationsMap.delegate = self
        locationsMap.addGestureRecognizer(longPressOnMapGesture)
        
        restoreMapRegion(false)
    }

    override func setEditing(editing: Bool, animated: Bool) {
        println("editing: \(editing)")
        super.setEditing(editing, animated: animated)
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
            
            println("lat: \(latitude), lon: \(longitude), latD: \(latitudeDelta), lonD: \(longitudeDelta)")
            
            locationsMap.setRegion(savedRegion, animated: animated)
        }
    }

}



// MARK: Conforming to MKMapViewDelegate and handling of gestures

extension LocationsViewController : MKMapViewDelegate {

    func handleLongPressOnMap(gestureRecognizer : UIGestureRecognizer){
        switch gestureRecognizer.state {
        case .Began :
            let touchPoint = gestureRecognizer.locationInView(self.locationsMap)
            let touchMapCoordinate = self.locationsMap.convertPoint(touchPoint,
                toCoordinateFromView: self.locationsMap)
            
            movingAnnotation = MKPointAnnotation()
            movingAnnotation!.coordinate = touchMapCoordinate
            locationsMap.addAnnotation(movingAnnotation)
            
        case .Changed :
            let touchPoint = gestureRecognizer.locationInView(self.locationsMap)
            let touchMapCoordinate = self.locationsMap.convertPoint(touchPoint,
                toCoordinateFromView: self.locationsMap)
            
            movingAnnotation!.coordinate = touchMapCoordinate
            
        case .Ended :
            println("ending")
        default:
            println("state: \(gestureRecognizer.state)")
        }
    }
    
    func mapView(mapView: MKMapView!, didSelectAnnotationView view: MKAnnotationView!) {
        view.setDragState(.Dragging, animated: true)
    }
    
    func mapView(mapView: MKMapView!, annotationView view: MKAnnotationView!, didChangeDragState newState: MKAnnotationViewDragState, fromOldState oldState: MKAnnotationViewDragState) {
        println("from: \(oldState.rawValue) -- to: \(newState.rawValue)")
    }
    
    func mapView(mapView: MKMapView!, viewForAnnotation annotation: MKAnnotation!) -> MKAnnotationView! {
        let reuseId = "pin"
        var pinView = mapView.dequeueReusableAnnotationViewWithIdentifier(reuseId) as? MKPinAnnotationView
        if pinView == nil {
            pinView = MKPinAnnotationView(annotation: annotation, reuseIdentifier: reuseId)!
            pinView!.animatesDrop = true
            pinView!.pinColor = .Red
        } else {
            pinView!.annotation = annotation
        }
        return pinView
    }
    
    // Making changes of region on Map persistant
    func mapView(mapView: MKMapView!, regionDidChangeAnimated animated: Bool) {
        saveMapRegion()
    }
}