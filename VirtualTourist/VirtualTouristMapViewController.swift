//
//  VirtualTouristMapViewController.swift
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
import MapKit
import CoreData

class VirtualTouristMapViewController: UIViewController {

    // MARK: Outlets
    
    @IBOutlet weak var mapView: MKMapView!
    @IBOutlet var longPressGestureRecognizer: UILongPressGestureRecognizer!
    @IBOutlet weak var removePinLabel: UILabel!
    @IBOutlet weak var editBarButtonItem: UIBarButtonItem!
    
    // MARK: Properties
    
    fileprivate var isEditMode = false //true if we are in edit mode (i.e. can delete Pins)
    
    private lazy var fetchedResultsController: NSFetchedResultsController<Pin> = {
        let request = NSFetchRequest<Pin>(entityName: "Pin")
        request.sortDescriptors = [NSSortDescriptor(key: "latitude", ascending: true)]
        let fetchedResultsController = NSFetchedResultsController<Pin>(fetchRequest: request, managedObjectContext: CoreDataStack.shared.mainContext, sectionNameKeyPath: nil, cacheName: nil)
        return fetchedResultsController
    }()
    
    private struct AlphaValues {
        static let Opaque: CGFloat = 1.0
        static let Transparent: CGFloat = 0.0
    }
    
    // MARK: Life Cycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        mapView.delegate = self
        loadAndSetCoordinatesPreferences()
        longPressGestureRecognizer.addTarget(self, action: #selector(longPressureGestureRecognized(_:)))
        mapView.addGestureRecognizer(longPressGestureRecognizer)
        fetchedResultsController.delegate = self
        do {
            try fetchedResultsController.performFetch()
            loadAnnotationsFromFetchedResultsController()
        } catch {
            debugPrint(error.localizedDescription)
        }
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    
    // MARK: Actions
    
    @IBAction func editBarButtonItemTapped(_ sender: UIBarButtonItem) {
        isEditMode = !isEditMode
        UIView.animate(withDuration: 0.5) {
            if self.isEditMode {
                self.removePinLabel.alpha = AlphaValues.Opaque
                self.editBarButtonItem.title = "Done"
            } else {
                self.removePinLabel.alpha = AlphaValues.Transparent
                self.editBarButtonItem.title = "Edit"
            }
        }
    }
    
    // MARK: Utility
    
    @objc private func longPressureGestureRecognized(_ gestureRecognizer: UIGestureRecognizer) {
        if gestureRecognizer.state == .ended {
            let touchPoint = gestureRecognizer.location(in: mapView)
            let coordinates = mapView.convert(touchPoint, toCoordinateFrom: mapView)
            addPin(withLatitude: coordinates.latitude, withLongitude: coordinates.longitude)
        }
    }

    private func addPin(withLatitude latitude: Double, withLongitude longitude: Double) {
        let _ = Pin(latitude: latitude, longitude: longitude, inContext: CoreDataStack.shared.mainContext)
        //DispatchQueue.main.async {
        //    CoreDataStack.shared.save()
        //}
    }
    
    private func loadAnnotationsFromFetchedResultsController() {
        mapView.removeAnnotations(mapView.annotations)
        if let pins = fetchedResultsController.fetchedObjects {
            for pin in pins {
                mapView.addAnnotation(pin)
            }
        }
    }

}

// MARK: MKMapViewDelegate

extension VirtualTouristMapViewController: MKMapViewDelegate {
    
    func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
        let identifier = "Pin"
        var annotationView = mapView.dequeueReusableAnnotationView(withIdentifier: identifier)
        if annotationView == nil {
            annotationView = MKPinAnnotationView(annotation: annotation, reuseIdentifier: identifier)
        } else {
            annotationView!.annotation = annotation
        }
        annotationView!.canShowCallout = false
        
        return annotationView
    }
    
    func mapView(_ mapView: MKMapView, didSelect view: MKAnnotationView) {
        guard let pin = view.annotation as? Pin else {
            return
        }
        
        if isEditMode {
            CoreDataStack.shared.mainContext.delete(pin)
        } else {
            if let collectionVC = storyboard?.instantiateViewController(withIdentifier: "collectionViewController") as? VirtualTouristCollectionViewController {
                collectionVC.pin = pin
                mapView.deselectAnnotation(pin, animated: false)
                navigationController?.pushViewController(collectionVC, animated: true)
            }
        }
    }
    
    private struct MapKeys {
        static let RegionHasBeenSaved = "com.VirtualTourist.RegionHasBeenSaved"
        static let LastRegionLatitude = "com.VirtualTourist.Latitude"
        static let LastRegionLongitude = "com.VirtualTourist.Longitude"
        static let LastRegionLongitudeDelta = "com.VirtualTourist.LongitudeDelta"
        static let LastRegionLatitudeDelta = "com.VirtualTourist.LatitudeDelta"
    }
    
    func mapView(_ mapView: MKMapView, regionDidChangeAnimated animated: Bool) {
        storeCoordinatesPreferences()
    }
    
    private func storeCoordinatesPreferences() {
        let defaults = UserDefaults.standard
        defaults.setValue(true, forKey: MapKeys.RegionHasBeenSaved)
        let region = mapView.region
        defaults.set(region.center.latitude, forKey: MapKeys.LastRegionLatitude)
        defaults.set(region.center.longitude, forKey: MapKeys.LastRegionLongitude)
        defaults.set(region.span.latitudeDelta, forKey: MapKeys.LastRegionLatitudeDelta)
        defaults.set(region.span.longitudeDelta, forKey: MapKeys.LastRegionLongitudeDelta)
    }
    
    fileprivate func loadAndSetCoordinatesPreferences() {
        let defaults = UserDefaults.standard
        if defaults.bool(forKey: MapKeys.RegionHasBeenSaved) {
            var region = MKCoordinateRegion()
            region.center.latitude = defaults.double(forKey: MapKeys.LastRegionLatitude)
            region.center.longitude = defaults.double(forKey: MapKeys.LastRegionLongitude)
            region.span.latitudeDelta = defaults.double(forKey: MapKeys.LastRegionLatitudeDelta)
            region.span.longitudeDelta = defaults.double(forKey: MapKeys.LastRegionLongitudeDelta)
            mapView.setRegion(region, animated: true)
        }
    }
    
}

// MARK: NSFetchedResultControllerDelegate

extension VirtualTouristMapViewController: NSFetchedResultsControllerDelegate {
    
    func controller(_ controller: NSFetchedResultsController<NSFetchRequestResult>,
                    didChange anObject: Any,
                    at indexPath: IndexPath?,
                    for type: NSFetchedResultsChangeType,
                    newIndexPath: IndexPath?) {
        let pin = anObject as! Pin
        switch type {
        case .insert:
            mapView.addAnnotation(pin)
        case .delete:
            mapView.removeAnnotation(pin)
        /* This would cause the delegate to be notified even when photos relative to the
             pin would get updated/removed (i.e. in VirtualTouristCollectionViewController)
        case .move:
            fallthrough
        case .update:
            break
        */
        default:
            return
        }
        DispatchQueue.main.async {
            CoreDataStack.shared.save()
        }
    }
    
}
