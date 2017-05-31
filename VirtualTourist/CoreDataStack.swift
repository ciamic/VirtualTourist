//
//  CoreDataStack.swift
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

import CoreData


/**
 * The CoreDataStack contains the code that was previously living in the
 * AppDelegate. Apple puts the code in the AppDelegate in many of their
 * Xcode templates, but they put it in a convenience class like this in sample code
 * like the "Earthquakes" project.
 *
 * The code in this class follows the advices given in Udacity course "iOS Persistence and Core Data".
 * The stack has three contexts:
 *    - a persistent context whose purpose is to persist data on a background queue
 *    - a main context whose purpose is to display data in the main queue (child of the persistent context)
 *    - a background context whose purpose is to execute background tasks on a background queue (child of the main context)
 */

struct CoreDataStack {
    
    // MARK: Shared Instance
    
    static var shared: CoreDataStack {
        struct Singleton {
            static var sharedInstance = CoreDataStack(modelName: Constants.AppConstants.CoreDataModelName)!
        }
        
        return Singleton.sharedInstance
    }
    
    // MARK: Private Properties
    
    fileprivate let model: NSManagedObjectModel
    fileprivate let coordinator: NSPersistentStoreCoordinator
    fileprivate let modelURL: URL
    fileprivate let databaseURL: URL
    fileprivate let persistingContext: NSManagedObjectContext
    fileprivate let backgroundContext: NSManagedObjectContext
    
    // MARK: Properties
    
    let mainContext: NSManagedObjectContext
    
    // MARK: Initializers
    
    init?(modelName: String) {
        
        //get model url
        guard let modelURL = Bundle.main.url(forResource: modelName, withExtension: "momd") else {
            debugPrint("\(modelName) not found")
            return nil
        }
        
        self.modelURL = modelURL
        
        //create a model from url
        guard let model = NSManagedObjectModel(contentsOf: modelURL) else {
            debugPrint("Cannot create model from \(modelURL)")
            return nil
        }
        
        self.model = model
        
        //create store coordinator
        coordinator = NSPersistentStoreCoordinator(managedObjectModel: model)
        
        //create persisting context on a background queue
        //it's job is only to persist data
        persistingContext = NSManagedObjectContext(concurrencyType: .privateQueueConcurrencyType)
        persistingContext.persistentStoreCoordinator = coordinator
        
        //create main context on the main queue
        //it is child of the persisting context
        mainContext = NSManagedObjectContext(concurrencyType: .mainQueueConcurrencyType)
        mainContext.parent = persistingContext
        
        //create background context on a background queue
        //it is child of the main context
        backgroundContext = NSManagedObjectContext(concurrencyType: .privateQueueConcurrencyType)
        backgroundContext.parent = mainContext
        
        //get URL for store
        guard let docURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first else {
            debugPrint("Cannot find documents folder")
            return nil
        }
        
        self.databaseURL = docURL.appendingPathComponent("VirtualTouristModel.sqlite")
        
        //add store in documents folder
        do {
            try coordinator.addPersistentStore(ofType: NSSQLiteStoreType, configurationName: nil, at: databaseURL, options: nil)
        } catch {
            debugPrint("Cannot add store at \(databaseURL)")
            debugPrint(error.localizedDescription)
        }
        
    }

}

// MARK: Remove Data
    
extension CoreDataStack {

    ///
    /// drops all the data without deleting files
    ///
    func dropData() throws {
        try coordinator.destroyPersistentStore(at: databaseURL, ofType: NSSQLiteStoreType, options: nil)
        try coordinator.addPersistentStore(ofType: NSSQLiteStoreType, configurationName: nil, at: databaseURL, options: nil)
    }
        
}

// MARK: Background Tasks

extension CoreDataStack {
    
    typealias BatchOperation = (_ context: NSManagedObjectContext) -> ()
    
    ///
    /// performBackgroundBatchOperation allows to submit a batch closure that will
    /// run in the background and, once done, saves (i.e. pushes) changes from the
    /// background context to the main one.
    ///
    func performBackgroundBatchOperation(_ batch: @escaping BatchOperation) {
        backgroundContext.perform() {
            batch(self.backgroundContext)
            
            do {
                try self.backgroundContext.save()
            } catch {
                debugPrint(error.localizedDescription)
                fatalError("Error while saving the backgroundContext")
            }
        }
    }
    
}

// MARK: Persist

extension CoreDataStack {
    
    ///
    /// saves if any change has occurred
    ///
    func save() {
        
        // saving on the main context is very fast since it simply pushes data on the persistent context
        // hence we can call it as a synchronous operation since it will not hit the disk
        mainContext.performAndWait() {
            if self.mainContext.hasChanges {
                do {
                    try self.mainContext.save()
                } catch {
                    debugPrint(error.localizedDescription)
                    fatalError("Error while saving main context")
                }
                
                // once we have pushed data from main context, the persisting context can save the data.
                // This can take a perceivable amount of time to complete, but it's done on a background
                // queue so we have not to worry about it.
                self.persistingContext.perform() {
                    do {
                        try self.persistingContext.save()
                    } catch {
                        debugPrint(error.localizedDescription)
                        fatalError("Error while saving persisting context")
                    }
                }
            }
        }
        
    }
    
    ///
    /// automatically saves every given seconds
    /// param intervalInSeconds
    ///
    func autoSave(every intervalInSeconds: Double) {
        if intervalInSeconds > 0 {
            //debugPrint("Autosaving (every \(intervalInSeconds) seconds)...")
            save()
            // overloaded '+' func will take care of adding DispatchTime and Double
            let dispatchTime = DispatchTime.now() + intervalInSeconds
            DispatchQueue.main.asyncAfter(deadline: dispatchTime) {
                self.autoSave(every: intervalInSeconds)
            }
        }
    }
    
}
