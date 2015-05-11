//
//  DiscoverMapViewController.swift
//  SocialExplorer
//
//  Created by Humberto Aquino on 5/4/15.
//  Copyright (c) 2015 Humberto Aquino. All rights reserved.
//

import Foundation
import UIKit
import MapKit
import CoreData
import CoreLocation
import XCGLogger


class DiscoverMapViewController: UIViewController, MKMapViewDelegate , NSFetchedResultsControllerDelegate {
    
    let InterestingLocationReusableAnnotationId = "InterestingLocationReusableAnnotation"
    let ReferenceLocationSelectedSegueId = "ReferenceLocationSelected"
    
    let userSettings = UserSettings.sharedInstance()
    
    @IBOutlet weak var mapView: MKMapView!
    
    var sharedContext: NSManagedObjectContext!
    
    var longTapRecognizer: UILongPressGestureRecognizer!
    
    var selectedPinAnnotation: PinAnnotation!
    
    var referenceLocationsFetchedResultsController: NSFetchedResultsController!
    
    
    // MARK: View life cycle 
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Core Data
        sharedContext = CoreDataStackManager.sharedInstance().managedObjectContext
        
        // Setup delegate
        mapView.delegate = self
        
        // Setup long tap gesture recognizer to add pin locations
        longTapRecognizer = UILongPressGestureRecognizer(target: self, action: "handleLongTapGesture:")
        longTapRecognizer.minimumPressDuration = UI.MinimumPressDuration
      
        // Load previous map state
        loadMapViewRegion()
        
        // TODO: Handle the error with a alertview
        // Do the initial fetch
        var error: NSError?
        fetchedResultsController.performFetch(&error)
        
        if let error = error {
            logger.error("Error performing initial fetch: \(error)")
        }
        
        reloadAnnotationsToMapViewFromFetchedResults()
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        mapView.addGestureRecognizer(longTapRecognizer)
        
    }
    
    override func viewWillDisappear(animated: Bool) {
        super.viewWillDisappear(animated)
        mapView.removeGestureRecognizer(longTapRecognizer)
        
    }
    
    @IBAction func forceSyncAction(sender: UIBarButtonItem) {
        SyncManager.sharedInstance().sync()        
    }
    
    @IBAction func zoomToShowAllLocationsAction(sender: UIButton) {
        if referenceLocationsFetchedResultsController != nil {
            if let locations = referenceLocationsFetchedResultsController.fetchedObjects as? [CDLocation] {
                mapView.zoomToFitCoordenables(locations as NSArray)
            }
        }
    }
    
    @IBAction func zoomRoShowAllReferencesAction(sender: UIButton) {
        removeExistingLocationAnnotationsFromMap()
        if let references = fetchedResultsController.fetchedObjects as? [CDReference] {
            mapView.zoomToFitCoordenables(references as NSArray)
        }
    }
    

    // MARK: - UILongPressGestureRecognizer
    
    func handleLongTapGesture(gestureRecognizer: UIGestureRecognizer) {
        if gestureRecognizer.state != UIGestureRecognizerState.Began {
            return
        }
        logger.info("--> Long tap gesture")
        
        let tapPoint = gestureRecognizer.locationInView(mapView)
        let tapMapCoordiantes = mapView.convertPoint(tapPoint, toCoordinateFromView: mapView)
        
        saveNewReferenceUsing(tapMapCoordiantes)
    }
   

    
    // MARK: - MKMapViewDelegate

    func mapView(mapView: MKMapView!, viewForAnnotation annotation: MKAnnotation!) -> MKAnnotationView! {
        
        
        var annotationView:MKPinAnnotationView! = mapView.dequeueReusableAnnotationViewWithIdentifier(InterestingLocationReusableAnnotationId) as? MKPinAnnotationView
        
        if annotationView != nil {
            annotationView.annotation = annotation
        } else {
            annotationView = MKPinAnnotationView(annotation: annotation, reuseIdentifier: InterestingLocationReusableAnnotationId)
            annotationView.animatesDrop = false
        }
        
        configureAnnotationView(annotationView)
        
        let detailButton: UIButton = UIButton.buttonWithType(UIButtonType.DetailDisclosure) as! UIButton
        annotationView.rightCalloutAccessoryView = detailButton
        
        return annotationView
    }
    
    func mapView(mapView: MKMapView!, didSelectAnnotationView view: MKAnnotationView!) {
        let pinAnnotation = view.annotation as! PinAnnotation
        
        if pinAnnotation.model == CDReference.ModelName {
            if selectedPinAnnotation != pinAnnotation {
                logger.debug("New pin selected")
                
                selectedPinAnnotation = pinAnnotation
                
                referenceLocationsFetchedResultsController = setupReferenceLocationsFetchedResultsController()!
                var error: NSError?
                referenceLocationsFetchedResultsController.performFetch(&error)
                if let error = error {
                    logger.error("Error fetching locations for reference: \(error.localizedDescription)")
                }
                
                reloadSelectedReferenceLocationsFromMap()
                
            }
        }
        
    }
    
    func mapView(mapView: MKMapView!, annotationView view: MKAnnotationView!, calloutAccessoryControlTapped control: UIControl!) {
        if control == view.rightCalloutAccessoryView {
        let annotation = view.annotation as! PinAnnotation
            if annotation.model == CDReference.ModelName {
                // Mark the selected location to use it while preparing for segue
                selectedPinAnnotation = annotation
                performSegueWithIdentifier(ReferenceLocationSelectedSegueId, sender: self)
            } else if annotation.model == CDLocation.ModelName {
                // TODO: Segue to images at location
            }
        }
    }
    
    func mapView(mapView: MKMapView!, annotationView view: MKAnnotationView!, didChangeDragState newState: MKAnnotationViewDragState, fromOldState oldState: MKAnnotationViewDragState) {
            let pinAnnotation = view.annotation as! PinAnnotation
        
            if newState == MKAnnotationViewDragState.Ending {
                
                let reference = self.sharedContext.objectWithID(pinAnnotation.objectID) as! CDReference
                logger.debug("Pre reference: \(reference)")
                
                if reference.coordinate.latitude == pinAnnotation.coordinate.latitude &&
                    reference.coordinate.longitude == pinAnnotation.coordinate.longitude {
                    logger.warning("Coordinates did NOT change")
                }
                
                reference.coordinate = pinAnnotation.coordinate
                reference.markAsNew()
                
                logger.debug("Pos reference: \(reference)")
                
                
                
                sharedContext.save(nil)
                
                // Get the new location
                self.reverseGeocodeLocationForLocation(reference) { (error) in
                    SyncManager.sharedInstance().sync()
                }
            }
    }
    
    func mapView(mapView: MKMapView!, regionDidChangeAnimated animated: Bool) {
        saveMapViewRegion()
    }
    
    // MARK: - Segues
    
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        if segue.identifier == ReferenceLocationSelectedSegueId {
            let destination = segue.destinationViewController as! ReferenceViewController
            destination.selectedReference = sharedContext.objectWithID(selectedPinAnnotation.objectID) as! CDReference
            destination.hidesBottomBarWhenPushed = true
        }
    }
    
    
    // MARK: - Persistense
    
    func saveNewReferenceUsing(coordinate: CLLocationCoordinate2D) {
        let dict = [
            CDReference.Keys.Latitude: coordinate.latitude,
            CDReference.Keys.Longitude: coordinate.longitude
        ]
        
        // Save the new location
        let newReference = CDReference(dictionary: dict, context: sharedContext)
        CoreDataStackManager.sharedInstance().saveContext { hadChanges in
            
            // Get the address names
            self.reverseGeocodeLocationForLocation(newReference) {
                (error) in
                if let error = error {
                    self.showMessageWithTitle("Geocoder error", message: error.localizedDescription)
                }
                
                // Start the sync
                SyncManager.sharedInstance().sync()
            }
        }
    }
    
    func reverseGeocodeLocationForLocation(reference: CDReference, completion: (error: NSError?) -> Void) {
        let geocoder = CLGeocoder()
        let location = CLLocation(latitude: reference.latitude, longitude: reference.longitude)
        
        geocoder.reverseGeocodeLocation(location, completionHandler: { (placemarkArray, error) -> Void in
            if error != nil {
                // Geocoder error
                completion(error: error)
                return
            }
            
            var error: NSError?
            let placemarks = placemarkArray as! [CLPlacemark]
            if let placemark = placemarks.last {
                // Change the name of the location
                reference.name = placemark.name
            } else {
                // Geocoder returned succesfully but WITHOUT palcemarks
                error = ErrorUtils.errorForGeocoderWithoutPlacemarks()
            }
            
            CoreDataStackManager.sharedInstance().saveContext { hadChanges in
                completion(error: error)
            }
        })
    }
    
    // Utility method to start a fresh mapview
    func reloadAnnotationsToMapViewFromFetchedResults() {
        // remove all pins
        let currentAnnotations = mapView.annotations
        mapView.removeAnnotations(currentAnnotations)
        
        // add all of them
        let ferchedObjects = fetchedResultsController.fetchedObjects as! [CDReference]
        var pinAnnotations = [PinAnnotation]()
        for reference in ferchedObjects {
            let pinAnnotation = PinAnnotation(objectID: reference.objectID, coordinate: reference.coordinate, model: CDReference.ModelName)
            pinAnnotations.append(pinAnnotation)
        }
        
        mapView.addAnnotations(pinAnnotations)
    }
    
    func reloadSelectedReferenceLocationsFromMap() {
        
        removeExistingLocationAnnotationsFromMap()
        
        if selectedPinAnnotation != nil {
            let locations = referenceLocationsFetchedResultsController.fetchedObjects as! [CDLocation]
            var pinAnnotations = [PinAnnotation]()
            for location in locations {
                let pinAnnotation = PinAnnotation(objectID: location.objectID, coordinate: location.coordinate, model: CDLocation.ModelName)
                pinAnnotations.append(pinAnnotation)
            }
            mapView.addAnnotations(pinAnnotations)
        }
    }
    
    func removeExistingLocationAnnotationsFromMap() {
        let currentAnnotations = mapView.annotations as! [PinAnnotation]
        for annotation in currentAnnotations {
            if annotation.model == CDLocation.ModelName {
                mapView.removeAnnotation(annotation)
            }
        }
    }
    
    lazy var fetchedResultsController: NSFetchedResultsController = {
        
        let fetchRequest = NSFetchRequest(entityName: CDReference.ModelName)
        
        fetchRequest.sortDescriptors = []
        
        let fetchedResultsController = NSFetchedResultsController(fetchRequest: fetchRequest, managedObjectContext: self.sharedContext, sectionNameKeyPath: nil, cacheName: nil)
        fetchedResultsController.delegate = self
        
        return fetchedResultsController
    }()
    
    
    
    
    // MARK: - NSFetchedResultsControllerDelegate
    
    
    func controller(controller: NSFetchedResultsController, didChangeObject anObject: AnyObject, atIndexPath indexPath: NSIndexPath?, forChangeType type: NSFetchedResultsChangeType, newIndexPath: NSIndexPath?) {
        
        if let reference = anObject as? CDReference {
        
            switch type {
            case .Insert:
                fetchedResultsChangeInsert(reference)
                break
            case .Delete:
                fetchedResultsChangeDelete(reference)
                break
            case .Update:
                fetchedResultsChangeUpdate(reference)
                break
            case .Move:
                fetchedResultsChangeMove(reference)
                break
            }
        }
    }
    
    
    
    // MARK: NSFetchedResultsControllerDelegate utils
    
    func fetchedResultsChangeInsert(reference: CDReference) -> PinAnnotation {
        let annotation = PinAnnotation(objectID: reference.objectID, coordinate: reference.coordinate, model: CDReference.ModelName)
        mapView.addAnnotation(annotation)
        
        return annotation
    }
    
    func fetchedResultsChangeDelete(reference: CDReference) {
        if let pinAnnotation = mapView.findPinAnnotationWithObjectID(reference.objectID) {
            mapView.removeAnnotation(pinAnnotation)
        } else {
            logger.error("Delete called on unexisting pin annotation")
        }
    }
    
    func fetchedResultsChangeUpdate(reference: CDReference) {
        fetchedResultsChangeDelete(reference)
        let insertedPin = fetchedResultsChangeInsert(reference)
        
        if selectedPinAnnotation != nil && insertedPin.objectID == selectedPinAnnotation.objectID {
            mapView.selectAnnotation(insertedPin, animated: false)
        }
        
    }
    
    func fetchedResultsChangeMove(reference: CDReference) {
        // FIXME: Is this even called?
    }
    
    func configureAnnotationView(annotationView: MKPinAnnotationView) {
        let pinAnnotation = annotationView.annotation as! PinAnnotation
        
        if pinAnnotation.model == CDReference.ModelName {
            // Is a reference
            
            let reference = sharedContext.objectWithID(pinAnnotation.objectID) as! CDReference
            
            let referenceLocationCount = reference.locationList.count
            
            pinAnnotation.title = reference.name
            pinAnnotation.subtitle = "\(referenceLocationCount) locations"
            
            if referenceLocationCount > 0 {
                annotationView.pinColor = MKPinAnnotationColor.Green
                annotationView.draggable = true
                annotationView.canShowCallout = true
            } else {
                annotationView.draggable = false
                annotationView.canShowCallout = false
                annotationView.pinColor = MKPinAnnotationColor.Red
            }
        } else {
            // Is a location
            let location = sharedContext.objectWithID(pinAnnotation.objectID) as! CDLocation
            pinAnnotation.title = location.name
            pinAnnotation.subtitle = location.subtitle
            
            var image = UIImage(named: "MiniInstagram")
            
            annotationView.image = image
            annotationView.canShowCallout = true
            
            if location.mediaList.count == 0 {
                annotationView.alpha = 0.5
            } else {
                annotationView.alpha = 1.0
            }
        }
        
    }
    
    
    // MARK: - Persistence utils
    
    // Load the saved region if exists in NSUserData
    func loadMapViewRegion() {
        if let region = userSettings.discoveryMap.loadMapRegion() {
            // A saved region exists
            mapView.region.center = CLLocationCoordinate2D(latitude: region.center.latitude, longitude: region.center.longitude)
            mapView.region.span = MKCoordinateSpan(latitudeDelta: region.span.latitudeDelta, longitudeDelta: region.span.longitudeDelta)
        }
    }
    
    func saveMapViewRegion() {
        userSettings.discoveryMap.saveMapRegion(mapView.region)
    }
    
    // MARK: - Utils
    
}


// MARK: Reference's locations

extension DiscoverMapViewController {

    func selectedReference() -> CDReference? {
        if selectedPinAnnotation != nil {
            if selectedPinAnnotation.model == CDReference.ModelName {
                let reference = sharedContext.objectWithID(selectedPinAnnotation.objectID) as! CDReference
                return reference
            }
        }
        return nil
    }
    
    func setupReferenceLocationsFetchedResultsController() -> NSFetchedResultsController? {
        if let selectedReference = self.selectedReference() {
            var fetchRequest = NSFetchRequest(entityName: CDLocation.ModelName)
            
            let referenceListPredicate = NSPredicate(format: "referenceList contains[c] %@", selectedReference)
            let mediaListNonEmptyPredicate = NSPredicate(format: "mediaList.@count > 0")
            
            fetchRequest.predicate = NSCompoundPredicate(type: NSCompoundPredicateType.AndPredicateType, subpredicates: [referenceListPredicate, mediaListNonEmptyPredicate])
            
            fetchRequest.sortDescriptors = []
            
            let fetchedResultsController = NSFetchedResultsController(fetchRequest: fetchRequest, managedObjectContext: self.sharedContext, sectionNameKeyPath: nil, cacheName: nil)

            fetchedResultsController.delegate = self
            
            return fetchedResultsController
        }
        
        return nil
    }
}


extension MKMapView {
    func findPinAnnotationWithObjectID(objectID: NSManagedObjectID) -> PinAnnotation? {
        let pinAnnotations = self.annotations as! [PinAnnotation]
        for pinAnnotation in pinAnnotations {
            if pinAnnotation.objectID == objectID {
                return pinAnnotation
            }
        }
        return nil
    }
}
