//
//  FlickrAPI.swift
//  VirtualTourist
//
//  Created by Victor Guerra on 18/09/15.
//  Copyright (c) 2015 Victor Guerra. All rights reserved.
//

import Alamofire
import UIKit

let LAT_MIN = -90.0
let LAT_MAX = 90.0
let LON_MIN = -180.0
let LON_MAX = 180.0
let BOX_HALF_SIZE = 1.0

let API_KEY = "ce1320875796d2144601f359b5410d43"

func getPhotoFromURL(url url: String, completionHandler : (image : UIImage) -> Void) {
    
    Alamofire.request(Method.GET, url, parameters: nil, encoding: ParameterEncoding.URL, headers: nil).response() {
        _, _ , data, error in
        
        switch (data, error) {
        case (.None, .None):
            break
        
        case let (.Some(data), _):
            if let img = UIImage(data: data) {
                completionHandler(image: img)
            } else {
                print("problem fetching img @ url \(url)")
                // probably a good approach would be to re-fetch the image here.
            }
            break
        case let (.None, .Some(error)):
            print("Got error while fetching image: \(error)")
            break
        default:
            break
        }
    }
}


func getPhotosByLocation(latitude latitude: Double, longitude: Double,
    completionHandler : ([[String : String]]) -> Void) {
    
    let URLparameters = [
        "method" : "flickr.photos.search",
        "api_key" : API_KEY,
        "bbox" : computeBBox(latitude: latitude, longitude: longitude),
        "safe_search" : "1",
        "extras" :  "url_m, description",
        "format" : "json",
        "nojsoncallback" : "1",
        "per_page" : "500",
        "page" : "1"
    ]
    
    Alamofire.request(Method.GET, "https://api.flickr.com/services/rest/", parameters: URLparameters, encoding: ParameterEncoding.URL, headers: nil).responseJSON() { _, _, data in
        
        switch data {
        
        case .Success(let parsedResult):
            let results = parsedResult["photos"] as! [String : AnyObject]
            let photos = results["photo"] as! [[String : AnyObject]]
            let photoDicts = photos.map() {
                return [Photo.Keys.PhotoId : $0["id"] as! String,
                    Photo.Keys.PhotoTitle : $0["title"]! as! String,
                    Photo.Keys.PhotoURL : $0["url_m"]! as! String
                ]
            }
            print("photoURLs count: \(photoDicts.count)")

            completionHandler(photoDicts)
            
        case .Failure(_, let error):
            print("Request failed w/error: \(error)")
        }
    }
    
}

func computeBBox(latitude latitude: Double, longitude: Double) -> String {
    
    let bottom_left_lat = max(latitude - BOX_HALF_SIZE, LAT_MIN)
    let bottom_left_lon = max(longitude - BOX_HALF_SIZE, LON_MIN)
    let top_right_lat = min(latitude + BOX_HALF_SIZE, LAT_MAX)
    let top_right_lon = min(longitude + BOX_HALF_SIZE, LON_MAX)
    
    return "\(bottom_left_lon),\(bottom_left_lat),\(top_right_lon),\(top_right_lat)"
}