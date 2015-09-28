//
//  PhotoAlbumViewController.swift
//  VirtualTourist
//
//  Created by Victor Guerra on 05/08/15.
//  Copyright (c) 2015 Victor Guerra. All rights reserved.
//

import UIKit
import MapKit
import CoreData


class PhotoAlbumViewController : UIViewController, NSFetchedResultsControllerDelegate, UICollectionViewDataSource, UICollectionViewDelegate {

    var pin : Pin!
    
    @IBOutlet weak var map: MKMapView!
    @IBOutlet weak var photoCollectionView: UICollectionView!
    @IBOutlet weak var flowLayout: UICollectionViewFlowLayout!
    
    @IBOutlet weak var newCollectionButton: UIButton!
    
    
    lazy var sharedContext: NSManagedObjectContext =  {
        return CoreDataStackManager.sharedInstance.managedObjectContext!
    }()
    
    lazy var fetchedResultsController : NSFetchedResultsController = {
        let fetchRequest = NSFetchRequest(entityName: "Photo")
        fetchRequest.sortDescriptors = []
        fetchRequest.predicate = NSPredicate(format: "pin == %@", self.pin)
        
        let fetchedResultsController = NSFetchedResultsController(fetchRequest: fetchRequest, managedObjectContext: self.sharedContext, sectionNameKeyPath: nil, cacheName: nil)
        
        return fetchedResultsController
    } ()
    
    // MARK: - Core Data Convenience
    
    func saveContext() {
        CoreDataStackManager.sharedInstance.saveContext()
    }

    //MARK: View Controller Life cycle
    
    override func viewDidLoad() {
        
        super.viewDidLoad()
        
        self.navigationItem.title = "Virtual Tourist"

        map.setCenterCoordinate(pin.coordinate, animated: false)
        map.addAnnotation(pin)
        
        photoCollectionView.registerClass(PhotoThumbnailCell.self, forCellWithReuseIdentifier: "photoThumbnailCell")
        photoCollectionView.allowsMultipleSelection = true
        
        do {
            try fetchedResultsController.performFetch()
        } catch _ {
            //do nothing if fetch fails
        }
        
        fetchedResultsController.delegate = self
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        
        let minSpace : CGFloat = 2.0
        var width : CGFloat
        if (UIApplication.sharedApplication().statusBarOrientation == .Portrait) {
            width = CGRectGetWidth(photoCollectionView!.frame)
        } else {
            width = CGRectGetHeight(photoCollectionView!.frame)
        }
        width = (width - 4*minSpace) / 3.0
        flowLayout.itemSize = CGSize(width: width, height: width)
        flowLayout.minimumInteritemSpacing = minSpace
        flowLayout.minimumLineSpacing = minSpace
        flowLayout.sectionInset = UIEdgeInsets(top: minSpace, left: minSpace, bottom: minSpace, right: minSpace)
    }
    

    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        
        if self.pin.photos.isEmpty {
            print("Need to fetch photos")
            getPhotosByLocation(latitude: pin.latitude, longitude: pin.longitude) {
                photosDicts in
                
                print("array of photo dicts has: \(photosDicts.count)")
                let copyPhotosDicts = photosDicts.shuffle()[0..<15]

                print("but copy has only: \(copyPhotosDicts.count)")
                
                print(copyPhotosDicts.count)
                let _ = copyPhotosDicts.map() {
                    (dict : [String : String]) -> Photo in
                    let photo = Photo(dictionary: dict, context: self.sharedContext)
                    photo.pin = self.pin
                    return photo
                }
                
                self.saveContext()

                dispatch_async(dispatch_get_main_queue()) {
                    self.photoCollectionView.reloadData()
                }

            }
        } else {
            print("reloading data")
            print(fetchedResultsController.fetchedObjects?.count)
        }
    }
    
    func goBack() {
        self.dismissViewControllerAnimated(true, completion: nil)
    }
    
    
    @IBAction func newCollection(sender: AnyObject) {
        fetchedResultsController.fetchedObjects?.forEach() {
            sharedContext.deleteObject($0 as! Photo)
            self.saveContext()
        }
    }
    
    // MARK: Conforming to the UICollectionViewDataSource protocol
    
    func collectionView(collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return fetchedResultsController.fetchedObjects?.count ?? 0
    }
    
    func collectionView(collectionView: UICollectionView, cellForItemAtIndexPath indexPath: NSIndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCellWithReuseIdentifier("photoThumbnailCell", forIndexPath: indexPath) as! PhotoThumbnailCell
        cell.photo = fetchedResultsController.objectAtIndexPath(indexPath) as! Photo
        cell.showImage()
        return cell
    }
    
    // MARK: Conforming to the UICollectionViewDelegate protocol
    func collectionView(collectionView: UICollectionView, didSelectItemAtIndexPath indexPath: NSIndexPath) {
        let cell = collectionView.cellForItemAtIndexPath(indexPath) as! PhotoThumbnailCell
        cell.toogleSeleted()
    }
    
    func collectionView(collectionView: UICollectionView, didDeselectItemAtIndexPath indexPath: NSIndexPath) {
        let cell = collectionView.cellForItemAtIndexPath(indexPath) as! PhotoThumbnailCell
        cell.toogleSeleted()
    }
    

    //    MARK: Conforming to NSFetchedResultsControllerDelegate protocol
    func controllerWillChangeContent(controller: NSFetchedResultsController) {
        print("will start changes")
    }
    
    func controllerDidChangeContent(controller: NSFetchedResultsController) {
        print("done w/changes")
    }
    
    func controller(controller: NSFetchedResultsController, didChangeObject anObject: AnyObject, atIndexPath indexPath: NSIndexPath?, forChangeType type: NSFetchedResultsChangeType, newIndexPath: NSIndexPath?) {
        switch type {
        case .Delete :
            photoCollectionView.deleteItemsAtIndexPaths([indexPath!])
            break
        default :
            print("an was added/changed")
        }
    }
}
