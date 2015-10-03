//
//  PhotoThumbnailCell.swift
//  VirtualTourist
//
//  Created by Victor Guerra on 15/09/15.
//  Copyright (c) 2015 Victor Guerra. All rights reserved.
//

import UIKit

class PhotoThumbnailCell : UICollectionViewCell {
    var activityIndicator : UIActivityIndicatorView!
    var activityView : UIView!
    var imageView : UIImageView!
    var selectedView : UIView!
    var activityLabel : UILabel!
    var photo : Photo!
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        activityView = UIView(frame: CGRectMake(0, 0, frame.size.width, frame.size.height))
        imageView = UIImageView(frame: CGRectMake(0, 0, frame.size.width, frame.size.height))
        imageView.hidden = true
        imageView.contentMode = .ScaleToFill
        
        selectedView = UIView(frame: CGRectMake(0, 0, frame.size.width, frame.size.height))
        selectedView.backgroundColor = UIColor(red: 1.0, green: 1.0, blue: 1.0, alpha: 0.5)
        selectedView.hidden = true

        activityView.backgroundColor = UIColor(red: 0, green: 0, blue: 0, alpha: 0.7)
        activityView.clipsToBounds = true;
        activityView.layer.cornerRadius = 10.0;
        activityView.hidden = true
        activityIndicator = UIActivityIndicatorView(activityIndicatorStyle: .WhiteLarge)
        activityIndicator.frame = CGRectMake(0, 0, activityView.bounds.size.width, activityView.bounds.size.height)
        activityIndicator.hidesWhenStopped = true
        
        activityLabel = UILabel(frame: CGRectMake(0, 0, 130, 22))
        activityLabel.backgroundColor = UIColor.clearColor()
        activityLabel.textColor = UIColor.whiteColor()
        activityLabel.adjustsFontSizeToFitWidth = true
        activityLabel.textAlignment = NSTextAlignment.Center
        
        activityView.addSubview(activityLabel)
        activityView.addSubview(activityIndicator)
        
        contentView.addSubview(imageView)
        contentView.addSubview(selectedView)
        contentView.addSubview(activityView)
        
    }

    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    func resetState() {
        activityView.hidden = true
        imageView.hidden = true
        toggleSelected()
    }
    
    func showImage() {
        if let image = photo.image {
            imageView.image = image
            imageView.hidden = false
        } else {
            self.startActivityAnimation(message: "Loading...")
            getPhotoFromURL(url: photo.photoURL!) {
                image in
                self.photo.image = image
                self.imageView.hidden = false
                self.imageView.image = image
                self.stopActivityAnimation()
                self.stopActivityAnimation()
            }
        }
    }
    
    func toggleSelected() {
        self.selectedView.hidden = !self.selected
    }
    
    func startActivityAnimation(message message: String) {
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