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

let downloadIsDone = "com.vguerra.downloadIsDoneKey"

class PhotoAlbumViewController : UIViewController, NSFetchedResultsControllerDelegate, UICollectionViewDataSource, UICollectionViewDelegate {

    var pin : Pin!
    var indexPathsInserted : [NSIndexPath]!
    var indexPathsDeleted : [NSIndexPath]!
    
    var activityIndicator : UIActivityIndicatorView! = nil
    var activityView : UIView! = nil
    var activityLabel : UILabel! = nil

    
    @IBOutlet weak var map: MKMapView!
    @IBOutlet weak var photoCollectionView: UICollectionView!
    @IBOutlet weak var flowLayout: UICollectionViewFlowLayout!
    @IBOutlet weak var newCollectionButton: UIButton!
    @IBOutlet weak var noPhotosFoundLabel: UILabel!
    
    var selectedPhotos : Int {
        return photoCollectionView.indexPathsForSelectedItems()?.count ?? 0
    }
    
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
    
    var photosToDownload : Int = 0 {
        didSet {
            if oldValue == 0 && photosToDownload != 0 {
                newCollectionButton.enabled = false
            } else if photosToDownload == 0 {
                newCollectionButton.enabled = true
            }
        }
    }
    
    // MARK: - Core Data Convenience
    
    func saveContext() {
        CoreDataStackManager.sharedInstance.saveContext()
    }

    //MARK: View Controller Life cycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        setUpUIElements()
        
        photoCollectionView.hidden = false
        noPhotosFoundLabel.hidden = true
        
        self.navigationItem.title = "Virtual Tourist"

        let viewRegion = MKCoordinateRegionMakeWithDistance(pin.coordinate, 500, 500)
        map.setCenterCoordinate(pin.coordinate, animated: false)
        map.setRegion(viewRegion, animated: false)
        map.addAnnotation(pin)
        map.scrollEnabled = false
        
        photoCollectionView.registerClass(PhotoThumbnailCell.self, forCellWithReuseIdentifier: "photoThumbnailCell")
        photoCollectionView.allowsMultipleSelection = true
        
        do {
            try fetchedResultsController.performFetch()
        } catch _ {
            //do nothing if fetch fails
        }
        
        fetchedResultsController.delegate = self
        
        // we want to be notified when a download gets done
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "imageDownloadDone", name: downloadIsDone, object: nil)
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
            fetchPhotosFromFlickr()
        }
    }
    
    func imageDownloadDone() {
        self.photosToDownload--
    }
    
    func fetchPhotosFromFlickr() {
        // while we download images we dissable the new button
        self.startActivityAnimationWithMessage("Loading Collection...")
        photosToDownload = 15 - photoCollectionView.numberOfItemsInSection(0)
        getPhotosByLocation(latitude: pin.latitude, longitude: pin.longitude) {
            photosDicts in

            self.stopActivityAnimation()
            if photosDicts.count == 0 {
                dispatch_async(dispatch_get_main_queue()) {
                    self.photoCollectionView.hidden = true
                    self.noPhotosFoundLabel.hidden = false
                    self.newCollectionButton.enabled = true
                }
                return
            }
            
            let copyPhotosDicts = photosDicts.shuffle()[0..<self.photosToDownload]
            let _ = copyPhotosDicts.map() {
                (dict : [String : String]) -> Photo in
                let photo = Photo(dictionary: dict, context: self.sharedContext)
                photo.pin = self.pin
                return photo
            }
            self.saveContext()
        }
    }
    
    func goBack() {
        self.dismissViewControllerAnimated(true, completion: nil)
    }
    
    func changenButtonTitle(title title: String) {
        UIView.performWithoutAnimation() {
            self.newCollectionButton.setTitle(title, forState: .Normal)
            self.newCollectionButton.layoutIfNeeded()
        }
    }
    
    @IBAction func newCollection(sender: AnyObject) {
        self.noPhotosFoundLabel.hidden = true
        self.photoCollectionView.hidden = false
        
        if selectedPhotos == 0 {
            fetchedResultsController.fetchedObjects?.forEach() {
                self.sharedContext.deleteObject($0 as! Photo)
            }
            self.saveContext()
            fetchPhotosFromFlickr()
        } else {
            let photosToDelete = photoCollectionView.indexPathsForSelectedItems()?.map() {
                fetchedResultsController.objectAtIndexPath($0) as! Photo
            }
            photosToDelete?.forEach() {
                self.sharedContext.deleteObject($0)
            }
            self.saveContext()
            changenButtonTitle(title: "New Collection")
        }
    }
    // MARK: Conforming to the UICollectionViewDataSource protocol
    
    func collectionView(collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return fetchedResultsController.fetchedObjects?.count ?? 0
    }
    
    func collectionView(collectionView: UICollectionView, cellForItemAtIndexPath indexPath: NSIndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCellWithReuseIdentifier("photoThumbnailCell", forIndexPath: indexPath) as! PhotoThumbnailCell
        cell.photo = fetchedResultsController.objectAtIndexPath(indexPath) as! Photo
        cell.resetState()
        cell.showImage()
        return cell
    }
    
    // MARK: Conforming to the UICollectionViewDelegate protocol
    
    
    
    func collectionView(collectionView: UICollectionView, didSelectItemAtIndexPath indexPath: NSIndexPath) {
        let cell = collectionView.cellForItemAtIndexPath(indexPath) as! PhotoThumbnailCell
        cell.toggleSelected()
        if selectedPhotos == 1 {
            changenButtonTitle(title: "Delete selected Photos")
        }
    }
    
    func collectionView(collectionView: UICollectionView, didDeselectItemAtIndexPath indexPath: NSIndexPath) {
        let cell = collectionView.cellForItemAtIndexPath(indexPath) as! PhotoThumbnailCell
        cell.toggleSelected()
        if selectedPhotos == 0 {
            changenButtonTitle(title: "New Collection")
        }
    }
    
    //    MARK: Conforming to NSFetchedResultsControllerDelegate protocol
    func controllerWillChangeContent(controller: NSFetchedResultsController) {
        indexPathsInserted = [NSIndexPath]()
        indexPathsDeleted = [NSIndexPath]()
    }
    
    func controllerDidChangeContent(controller: NSFetchedResultsController) {
        photoCollectionView.performBatchUpdates({
            self.photoCollectionView.deleteItemsAtIndexPaths(self.indexPathsDeleted)
            self.photoCollectionView.insertItemsAtIndexPaths(self.indexPathsInserted)
            }, completion: nil)
    }
    
    func controller(controller: NSFetchedResultsController, didChangeObject anObject: AnyObject, atIndexPath indexPath: NSIndexPath?, forChangeType type: NSFetchedResultsChangeType, newIndexPath: NSIndexPath?) {
        switch type {
        case .Insert :
            indexPathsInserted.append(newIndexPath!)
        case .Delete :
            indexPathsDeleted.append(indexPath!)
        default :
            break
        }
    }
    
    // MARK: Activity animation code
    
    func setUpUIElements() {
        let sideLength:CGFloat = 170.0
        activityView = UIView(frame: CGRectMake(self.view.bounds.width/2 - sideLength/2,
            self.view.bounds.height/2 - sideLength/2, sideLength, sideLength))
        activityView.backgroundColor = UIColor(red: 0, green: 0, blue: 0, alpha: 0.7)
        activityView.clipsToBounds = true;
        activityView.layer.cornerRadius = 10.0;
        activityView.hidden = true
        activityIndicator = UIActivityIndicatorView(activityIndicatorStyle: .WhiteLarge)
        activityIndicator.frame = CGRectMake(0, 0, activityView.bounds.size.width, activityView.bounds.size.height)
        activityIndicator.hidesWhenStopped = true
        
        
        
        activityLabel = UILabel(frame: CGRectMake(20, 115, 130, 22))
        activityLabel.backgroundColor = UIColor.clearColor()
        activityLabel.textColor = UIColor.whiteColor()
        activityLabel.adjustsFontSizeToFitWidth = true
        activityLabel.textAlignment = NSTextAlignment.Center
        
        activityView.addSubview(activityLabel)
        activityView.addSubview(activityIndicator)
        self.view.addSubview(activityView)
    }

    func startActivityAnimationWithMessage(message: String) {
        dispatch_async(dispatch_get_main_queue()) {
            self.activityLabel.text = message
            self.activityView.hidden = false
            self.activityIndicator.startAnimating()
        }
    }
    
    func stopActivityAnimation() {
        dispatch_async(dispatch_get_main_queue()) {
            self.activityIndicator.stopAnimating()
            self.activityView.hidden = true
        }
    }

    
    
}
