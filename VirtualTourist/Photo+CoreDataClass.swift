//
//  Photo+CoreDataClass.swift
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
import CoreData
import UIKit

@objc(Photo)
public class Photo: NSManagedObject {
    
    // MARK: Properties
    
    var image: UIImage? {
        if let imageData = data {
            return UIImage(data: imageData as Data)
        } else {
            return nil
        }
    }
    
    // MARK: Initializers
    
    override init(entity: NSEntityDescription, insertInto context: NSManagedObjectContext?) {
        super.init(entity: entity, insertInto: context)
    }
    
    init(imageUrl: URL, context: NSManagedObjectContext) {
        if let entity = NSEntityDescription.entity(forEntityName: "Photo", in: context) {
            super.init(entity: entity, insertInto: context)
            self.url = imageUrl.absoluteString
        } else {
            fatalError("Unable to find Photo entity!")
        }
    }
    
    // MARK: Static "Initializers"
    
    static func photoFromURL(_ url: URL, context: NSManagedObjectContext) -> Photo {
        return Photo(imageUrl: url, context: context)
    }
    
    static func photosFromArrayOfURLs(_ URLs: [URL], context: NSManagedObjectContext) -> [Photo] {
        var photos = [Photo]()
        for url in URLs {
            photos.append(photoFromURL(url, context: context))
        }
        
        return photos
    }

}
