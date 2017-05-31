//
//  VirtualTouristCollectionViewController.swift
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

import UIKit
import CoreData
import PromiseKit

class VirtualTouristCollectionViewController: UIViewController {
    
    // MARK: Model
    
    var pin: Pin?
    
    // MARK: Outlets
    
    @IBOutlet weak var spinner: UIActivityIndicatorView!
    @IBOutlet weak var newCollectionButton: UIButton!
    @IBOutlet weak var collectionView: UICollectionView!
    
    fileprivate var removeBarButtonItem: UIBarButtonItem!
    
    // MARK: Properties
    
    //we use an array of block operations in order to handle multiple
    //operations on the collection view in response to the fetched
    //results controller changes.
    fileprivate var collectionViewOperations = [BlockOperation]()
    
    lazy var fetchedResultsController: NSFetchedResultsController<Photo> = {
        let request = NSFetchRequest<Photo>(entityName: "Photo")
        request.sortDescriptors = [NSSortDescriptor(key: "url", ascending: true)]
        request.predicate = NSPredicate(format: "pin == %@", self.pin!)
        let fetchedResultsController = NSFetchedResultsController(fetchRequest: request, managedObjectContext: CoreDataStack.shared.mainContext, sectionNameKeyPath: nil, cacheName: nil)
        return fetchedResultsController
    }()
    
    // MARK: Life Cycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        collectionView.delegate = self
        collectionView.dataSource = self
        collectionView.allowsMultipleSelection = true
        fetchedResultsController.delegate = self
        removeBarButtonItem = UIBarButtonItem(title: "Remove", style: .plain, target: self, action: #selector(removeBarButtonItemTapped))
        do {
            try fetchedResultsController.performFetch()
        } catch {
            debugPrint(error.localizedDescription)
        }
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        if pin?.photos?.count == 0 {
            fetchImagesURL()
        }
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        for cell in collectionView.visibleCells as! [PhotoCollectionViewCell] {
            cell.cancelPromise()
        }
    }
    
    deinit {
        collectionViewOperations.forEach { $0.cancel() }
        collectionViewOperations.removeAll(keepingCapacity: false)
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    // MARK: Actions
    
    @IBAction func newCollectionButtonTapped() {
        if let photos = fetchedResultsController.fetchedObjects {
            for photo in photos {
                CoreDataStack.shared.mainContext.delete(photo)
            }
            
            CoreDataStack.shared.save()
        }
        
        fetchImagesURL()
    }
    
    // MARK: Utility
    
    fileprivate func fetchImagesURL() {
        guard let pin = pin else {
            return
        }
        
        UIApplication.shared.isNetworkActivityIndicatorVisible = true
        newCollectionButton.isEnabled = false
        spinner.startAnimating()
        FlickrClient.shared.flickrImagesURLAtLocation(latitude: pin.latitude, longitude: pin.longitude, inContext: CoreDataStack.shared.mainContext).then { urls -> Void in
            for photo in Photo.photosFromArrayOfURLs(urls, context: CoreDataStack.shared.mainContext) {
                pin.insertIntoPhotos(photo, at: pin.photos!.count)
                photo.pin = pin
            }
            
            DispatchQueue.main.async {
                self.collectionView.reloadData()
            }
            
        }.always {
            DispatchQueue.main.async {
                self.spinner.stopAnimating()
                UIApplication.shared.isNetworkActivityIndicatorVisible = false
                self.newCollectionButton.isEnabled = true
            }
        }.catch { error in
            debugPrint(error.localizedDescription)
            let alert = UIAlertController(title: Constants.Alert.ErrorTitle, message: Constants.Alert.ErrorMessage, preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: Constants.Alert.ActionOk, style: .default, handler: nil))
            self.present(alert, animated: true, completion: nil)
        }
    }
    
    @objc private func removeBarButtonItemTapped() {
        if let indexPaths = collectionView.indexPathsForSelectedItems {
            navigationItem.rightBarButtonItem = nil
            for indexPath in indexPaths {
                CoreDataStack.shared.mainContext.delete(fetchedResultsController.object(at: indexPath))
            }
        }
    }
    
    fileprivate func updateVisibilityForRemoveBarButtonItem() {
        if let selectedItems = collectionView.indexPathsForSelectedItems, selectedItems.count > 0 {
            navigationItem.rightBarButtonItem = removeBarButtonItem
        } else {
            navigationItem.rightBarButtonItem = nil
        }
    }

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */

}

// MARK: UICollectionViewDelegate and UICollectionViewDataSource

extension VirtualTouristCollectionViewController: UICollectionViewDelegate, UICollectionViewDataSource {
    
    private struct Storyboard {
        static let PhotoCellReuseIdentifier = "PhotoCellIdentifier"
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: Storyboard.PhotoCellReuseIdentifier, for: indexPath) as! PhotoCollectionViewCell
        let photo = fetchedResultsController.object(at: indexPath)
        configure(cell: cell, withPhoto: photo, atIndexPath: indexPath)
        return cell
    }
    
    private func configure(cell: PhotoCollectionViewCell, withPhoto photo: Photo, atIndexPath indexPath: IndexPath) {
        
        //reset previous image, if any.
        cell.imageView.image = nil
        
        if let image = photo.image {
            cell.imageView.image = image
        } else {
            if let url = photo.url, let photoUrl = URL(string: url) {
                UIApplication.shared.isNetworkActivityIndicatorVisible = true
                // NOTE: the activity indicator will be stopped by removeAllAnimations
                // on cell reuse (i.e. will be called by dequeueReusableCell).
                cell.spinner.startAnimating()
                let cancellablePromise = FlickrClient.shared.getImageData(atURL: photoUrl)
                cancellablePromise.then { [weak photo] data -> Void in
                    DispatchQueue.main.async {
                        if let image = UIImage(data: data) {
                            //only display the image if it's still visible, otherwise it's already been reused
                            if cell == self.collectionView.cellForItem(at: indexPath) {
                                cell.imageView.image = image
                            }
                            photo?.data = data as NSData
                        }
                    }
                }.always {
                    DispatchQueue.main.async {
                        UIApplication.shared.isNetworkActivityIndicatorVisible = false
                    }
                }.catch { error in
                    debugPrint(error.localizedDescription)
                }
                
                cell.cancellablePromise = cancellablePromise
            }
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return fetchedResultsController.fetchedObjects?.count ?? 0
    }
    
    func numberOfSections(in collectionView: UICollectionView) -> Int {
        return 1
    }

    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        updateVisibilityForRemoveBarButtonItem()
    }
    
    func collectionView(_ collectionView: UICollectionView, didDeselectItemAt indexPath: IndexPath) {
        updateVisibilityForRemoveBarButtonItem()
    }
    
    func collectionView(_ collectionView: UICollectionView, shouldSelectItemAt indexPath: IndexPath) -> Bool {
        if let cell = collectionView.cellForItem(at: indexPath) as? PhotoCollectionViewCell {
            return cell.imageView.image != nil
        }
        
        return false
    }
    
}

// MARK: NSFetchedResultsControllerDelegate

extension VirtualTouristCollectionViewController: NSFetchedResultsControllerDelegate {
    
    func controllerWillChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {
        for operation in collectionViewOperations {
            operation.cancel()
        }
        collectionViewOperations.removeAll()
    }
    
    func controller(_ controller: NSFetchedResultsController<NSFetchRequestResult>, didChange sectionInfo: NSFetchedResultsSectionInfo, atSectionIndex sectionIndex: Int, for type: NSFetchedResultsChangeType) {
        switch type {
        case .insert:
            collectionViewOperations.append(BlockOperation {
                self.collectionView.insertSections(IndexSet(integer: sectionIndex))
            })
        case .delete:
            collectionViewOperations.append(BlockOperation {
                self.collectionView.deleteSections(IndexSet(integer: sectionIndex))
            })
        default:
            return
        }
    }
    
    func controller(_ controller: NSFetchedResultsController<NSFetchRequestResult>, didChange anObject: Any, at indexPath: IndexPath?, for type: NSFetchedResultsChangeType, newIndexPath: IndexPath?) {
        switch type {
        case .insert:
            collectionViewOperations.append(BlockOperation {
                self.collectionView.insertItems(at: [newIndexPath!])
            })
        case .delete:
            collectionViewOperations.append(BlockOperation {
                self.collectionView.deleteItems(at: [indexPath!])
            })
        case .move:
            // cannot use the moveItem method of UICollectionView (e.g.
            // self.collectionView.moveItem(at: indexPath!, to: newIndexPath!))
            // we need to split it in two operations (see also Apple documentation)
            collectionViewOperations.append(BlockOperation {
                self.collectionView.deleteItems(at: [indexPath!])
                self.collectionView.insertItems(at: [newIndexPath!])
            })
        case .update:
            collectionViewOperations.append(BlockOperation {
                self.collectionView.reloadItems(at: [indexPath!])
            })
        }
        
        DispatchQueue.main.async {
            CoreDataStack.shared.save()
        }
    }
    
    func controllerDidChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {
        collectionView.performBatchUpdates({ 
            for operation in self.collectionViewOperations {
                operation.start()
            }
        }) { (finished) in
            self.collectionViewOperations.removeAll()
        }
    }
    
}
