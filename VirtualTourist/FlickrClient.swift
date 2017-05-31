//
//  FlickrClient.swift
//
//  Copyright (c) 2017 michelangelo
//
//  Permission is hereby granted, free of charge, to any person obtaining a copy
//  of this software and associated documentation files (the "Software"), to deal
//  in the Software without restriction, including without limitation the rights
//  to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
//  copies of the Software, and to permit persons to whom the Software is
//  furnished to do so, subject to the following conditions:
//
//  The above copyright notice and this permission notice shall be included in
//  all copies or substantial portions of the Software.
//
//  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
//  IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
//  FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
//  AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
//  LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
//  OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
//  THE SOFTWARE.

import Foundation
import SwiftyJSON
import PromiseKit
import Alamofire
import CoreData

///
/// FlickrClient allows to query for image urls given a specific longitude and latitude.
///

class FlickrClient {
    
    // MARK: Shared Instance
    
    class var shared: FlickrClient {
        struct Singleton {
            static var sharedInstance = FlickrClient()
        }
        
        return Singleton.sharedInstance
    }
    
    // MARK: Public API
    
    ///
    /// Returns a Promise with the Data of the image specified
    ///
    func getImageData(atURL url: URL) -> CancellablePromise<Data> {
        return CancellablePromise<Data> { fulfill, reject in
            Alamofire.request(url).validate().responseData { response in
                switch response.result {
                case .success(let data):
                    fulfill(data)
                case .failure(let error):
                    reject(error)
                }
            }
        }
    }
    
    ///
    /// Returns a Promise of image URLs at given latitude/longitude
    ///
    func flickrImagesURLAtLocation(latitude: Double, longitude: Double, inContext context: NSManagedObjectContext) -> Promise<[URL]> {
        
        return getRandomPage(withLatitude: latitude, withLongitude: longitude).then { randomPage -> Promise<[URL]> in
            return self.getImageUrls(withPageNumber: randomPage, withLatitude: latitude, withLongitude: longitude)
        }
        
    }
    
    // MARK: Helpers
    
    private func getRandomPage(withLatitude latitude: Double, withLongitude longitude: Double) -> Promise<Int> {
        
        return Promise { fulfill, reject in
         
            let minLatitude = FlickrConstants.Search.SearchLatRange.0
            let maxLatitude = FlickrConstants.Search.SearchLatRange.1
            let minLongitude = FlickrConstants.Search.SearchLonRange.0
            let maxLongitude = FlickrConstants.Search.SearchLonRange.1
            
            //check for latitude
            guard valueIsInRange(value: latitude, min: minLatitude, max: maxLatitude) else {
                reject(NSError(domain: Constants.AppConstants.AppName,
                               code: 0,
                               userInfo: [NSLocalizedDescriptionKey:FlickrConstants.ErrorMessages.LatitudeNotInRange]))
                return
            }
            
            //check for longitude
            guard valueIsInRange(value: longitude, min: minLongitude, max: maxLongitude) else {
                reject(NSError(domain: Constants.AppConstants.AppName,
                               code: 0,
                               userInfo: [NSLocalizedDescriptionKey:FlickrConstants.ErrorMessages.LongitudeNotInRange]))
                return
            }
            
            let methodParameters = getFlickrMethodParameters(withBBoxLatitude: latitude, withBBoxLongitude: longitude)
            let url = flickrURLFromParameters(parameters: methodParameters)
            let request = Alamofire.request(url)
            
            request.validate().responseData { response in
                switch response.result {
                case .success(let data):
                    let json = JSON(data: data)
                    guard json.error == nil,
                        json[FlickrConstants.ResponseKeys.Status].string == FlickrConstants.ResponseValues.OKStatus,
                        let dict = json[FlickrConstants.ResponseKeys.Photos].dictionary,
                        let totalPages = dict[FlickrConstants.ResponseKeys.Pages]?.int else {
                            reject(NSError(domain: Constants.AppConstants.AppName,
                                           code: 0,
                                           userInfo: [NSLocalizedDescriptionKey:FlickrConstants.ErrorMessages.ErrorRetreivingImages]))
                            return
                    }
                    
                    // pick a random page!
                    let pageLimit = min(totalPages, 40)
                    let randomPage = Int(arc4random_uniform(UInt32(pageLimit))) + 1
                    
                    fulfill(randomPage)
                    
                case .failure(let error):
                    reject(error)
                }
        
            }
            
        }
        
    }
    
    private func getImageUrls(withPageNumber pageNumber: Int,
                              withLatitude latitude: Double,
                              withLongitude longitude: Double) -> Promise<[URL]> {
        
        return Promise { fulfill, reject in
         
            let methodParameters = getFlickrMethodParameters(withBBoxLatitude: latitude,
                                                             withBBoxLongitude: longitude,
                                                             withPageNumber: pageNumber)
            let url = flickrURLFromParameters(parameters: methodParameters)
            let request = Alamofire.request(url)
            
            request.validate().responseData { response in
                switch response.result {
                case .success(let data):
                    let json = JSON(data: data)
                    guard json.error == nil,
                        json[FlickrConstants.ResponseKeys.Status].string == FlickrConstants.ResponseValues.OKStatus,
                        let photosDictionary = json[FlickrConstants.ResponseKeys.Photos].dictionary,
                        let photosArray = photosDictionary[FlickrConstants.ResponseKeys.Photo]?.array else {
                            reject(NSError(domain: Constants.AppConstants.AppName,
                                           code: 0,
                                           userInfo: [NSLocalizedDescriptionKey:FlickrConstants.ErrorMessages.ErrorRetreivingImages]))
                            return
                    }
                    
                    var result = [URL]()
                    for photoDictionary in photosArray {
                        if let imageURL = photoDictionary[FlickrConstants.ResponseKeys.MediumURL].string {
                            if let url = URL(string: imageURL) {
                                result.append(url)
                            }
                        }
                    }
                    
                    fulfill(result)
                    
                case .failure(let error):
                    reject(error)
                }
            }
            
        }
        
    }
    
    private func getFlickrMethodParameters(withBBoxLatitude latitude: Double,
                                           withBBoxLongitude longitude: Double,
                                           withPageNumber pageNumber: Int = -1) -> [String:AnyObject] {
        //fill Flickr request parameters
        var methodParameters = [
            FlickrConstants.ParameterKeys.Method: FlickrConstants.ParameterValues.SearchMethod,
            FlickrConstants.ParameterKeys.APIKey: FlickrConstants.ParameterValues.APIKey,
            FlickrConstants.ParameterKeys.BoundingBox: bboxString(latitude: latitude, longitude: longitude),
            FlickrConstants.ParameterKeys.SafeSearch: FlickrConstants.ParameterValues.UseSafeSearch,
            FlickrConstants.ParameterKeys.Extras: FlickrConstants.ParameterValues.MediumURL,
            FlickrConstants.ParameterKeys.Format: FlickrConstants.ParameterValues.ResponseFormat,
            FlickrConstants.ParameterKeys.NoJSONCallback: FlickrConstants.ParameterValues.DisableJSONCallback,
            FlickrConstants.ParameterKeys.PerPage: FlickrConstants.ParameterValues.PhotosPerPage
        ]
        
        if pageNumber > -1 {
            methodParameters[FlickrConstants.ParameterKeys.Page] = String(pageNumber)
        }
        
        return methodParameters as [String : AnyObject]
        
    }
    
    private func flickrURLFromParameters(parameters: [String:AnyObject]) -> URL {
        var components = URLComponents()
        components.scheme = FlickrConstants.HTTP.APIScheme
        components.host = FlickrConstants.HTTP.APIHost
        components.path = FlickrConstants.HTTP.APIPath
        components.queryItems = [URLQueryItem]()
        
        for (key, value) in parameters {
            let queryItem = URLQueryItem(name: key, value: "\(value)")
            components.queryItems!.append(queryItem)
        }
        
        return try! components.asURL()
    }
    
    private func bboxString(latitude: Double, longitude: Double) -> String {
        // ensure bbox is bounded by min and max latitude and longitude
        let minimumLon = max(longitude - FlickrConstants.Search.SearchBBoxHalfWidth, FlickrConstants.Search.SearchLonRange.0)
        let minimumLat = max(latitude - FlickrConstants.Search.SearchBBoxHalfHeight, FlickrConstants.Search.SearchLatRange.0)
        let maximumLon = min(longitude + FlickrConstants.Search.SearchBBoxHalfWidth, FlickrConstants.Search.SearchLonRange.1)
        let maximumLat = min(latitude + FlickrConstants.Search.SearchBBoxHalfHeight, FlickrConstants.Search.SearchLatRange.1)
        return "\(minimumLon),\(minimumLat),\(maximumLon),\(maximumLat)"
    }
    
    private func valueIsInRange(value: Double, min: Double, max: Double) -> Bool {
        return value >= min && value <= max
    }
    
}
