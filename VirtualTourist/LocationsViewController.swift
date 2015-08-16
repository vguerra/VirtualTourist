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
    
    override func viewDidLoad() {
        
        self.navigationItem.rightBarButtonItem = self.editButtonItem()
        
        // MapView configuration
        var longPressOnMapGesture = UILongPressGestureRecognizer(target: self,
            action: "handleLongPressOnMap:")
        longPressOnMapGesture.minimumPressDuration = 1.5
        locationsMap.delegate = self
        locationsMap.addGestureRecognizer(longPressOnMapGesture)
    }

    override func setEditing(editing: Bool, animated: Bool) {
            super.setEditing(editing, animated: animated)
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
}