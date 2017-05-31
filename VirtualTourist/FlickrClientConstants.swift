//
//  FlickrClientConstants.swift
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

// MARK: - Constants

struct FlickrConstants {
    
    // MARK: HTTP
    struct HTTP {
        static let APIScheme = "https"
        static let APIHost = "api.flickr.com"
        static let APIPath = "/services/rest"
    }
    
    // MARK: Search
    struct Search {
        static let SearchBBoxHalfWidth = 1.0
        static let SearchBBoxHalfHeight = 1.0
        static let SearchLatRange = (-90.0, 90.0)
        static let SearchLonRange = (-180.0, 180.0)
    }
    
    // MARK: Flickr ErrorMessages
    struct ErrorMessages {
        static let LatitudeNotInRange = "Latitude should be between " + String(Search.SearchLatRange.0) + " and " + String(Search.SearchLatRange.1)
        static let LongitudeNotInRange = "Longitude should be between " + String(Search.SearchLonRange.0) + " and " + String(Search.SearchLonRange.1)
        static let ErrorRetreivingImages = "An error has occurred while retreiving images. Try again."
    }
    
    // MARK: Flickr Parameter Keys
    struct ParameterKeys {
        static let Method = "method"
        static let APIKey = "api_key"
        static let GalleryID = "gallery_id"
        static let Extras = "extras"
        static let Format = "format"
        static let NoJSONCallback = "nojsoncallback"
        static let SafeSearch = "safe_search"
        static let Text = "text"
        static let BoundingBox = "bbox"
        static let Page = "page"
        static let PerPage = "per_page"
    }
    
    // MARK: Flickr Parameter Values
    struct ParameterValues {
        static let SearchMethod = "flickr.photos.search"
        static let APIKey = "c62452d8b2c3ed809d84822d100b4ae1"
        static let ResponseFormat = "json"
        static let DisableJSONCallback = "1" /* 1 means "yes" */
        static let GalleryPhotosMethod = "flickr.galleries.getPhotos"
        static let GalleryID = "5704-72157622566655097"
        static let MediumURL = "url_m"
        static let UseSafeSearch = "1"
        static let PhotosPerPage = "20"
    }
    
    // MARK: Flickr Response Keys
    struct ResponseKeys {
        static let Status = "stat"
        static let Photos = "photos"
        static let Photo = "photo"
        static let Title = "title"
        static let MediumURL = "url_m"
        static let Pages = "pages"
        static let Total = "total"
    }
    
    // MARK: Flickr Response Values
    struct ResponseValues {
        static let OKStatus = "ok"
    }
    
}
