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
    
    let ReferenceLocationSelectedSegueId = "ReferenceLocationSelected"
    
    let LocationPinReusableAnnotationId = "LocationPinReusableAnnotationId"
    let ReferencePinReusableAnnotationId = "ReferencePinReusableAnnotationId"
    
    let userSettings = UserSettings.sharedInstance()
    
    @IBOutlet weak var refreshButton: UIBarButtonItem!
    @IBOutlet weak var mapView: MKMapView!
    
    var sharedContext: NSManagedObjectContext!
    
    var longTapRecognizer: UILongPressGestureRecognizer!
    
    var selectedReferencePinAnnotation: PinAnnotation!
    var selectedLocationPinAnnotation: PinAnnotation!
    
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
        
        self.registerObservers()
        
        self.configureRefreshButton()
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        mapView.addGestureRecognizer(longTapRecognizer)
    }
    
    override func viewWillDisappear(animated: Bool) {
        super.viewWillDisappear(animated)
        mapView.removeGestureRecognizer(longTapRecognizer)
        
    }
    
    
    func registerObservers() {
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "handleSyncComplete:", name: SyncManagerEvent.SyncComplete.rawValue, object: nil)
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "handleSyncError:", name: SyncManagerEvent.SyncError.rawValue, object: nil)
         NSNotificationCenter.defaultCenter().addObserver(self, selector: "handleSyncStarted:", name: SyncManagerEvent.SyncStarted.rawValue, object: nil)
    }
    
    func unregisterObservers() {
        NSNotificationCenter.defaultCenter().removeObserver(self, name: SyncManagerEvent.SyncComplete.rawValue, object: nil)
        NSNotificationCenter.defaultCenter().removeObserver(self, name: SyncManagerEvent.SyncError.rawValue, object: nil)
        NSNotificationCenter.defaultCenter().removeObserver(self, name: SyncManagerEvent.SyncStarted.rawValue, object: nil)
    }
    
    func handleSyncComplete(notification: NSNotification) {
        logger.debug("Handling sync complete")
        reloadSelectedReferenceLocationsFromMap()
        self.configureRefreshButton()
    }
    
    func handleSyncError(notification: NSNotification) {
        logger.debug("Handling sync error")
        self.configureRefreshButton()
    }
    
    func handleSyncStarted(notification: NSNotification) {
        logger.debug("Handling sync started")
        
        self.refreshButtonToActivityView()
    }
    
    
    deinit {
        unregisterObservers()
    }
    
    func refreshButtonToActivityView() {
//        let activityView = UIActivityIndicatorView(frame: )
        let activityView = UIActivityIndicatorView(activityIndicatorStyle: UIActivityIndicatorViewStyle.Gray)
        activityView.frame = CGRect(x: 0, y: 0, width: 25, height: 25)
        activityView.hidesWhenStopped = true
//        activityView.sizeToFit()
        activityView.startAnimating()
//        activityView.autoresizingMask = UIViewAutoresizing.FlexibleLeftMargin | UIViewAutoresizing.FlexibleRightMargin | UIViewAutoresizing.FlexibleTopMargin | UIViewAutoresizing.FlexibleBottomMargin
        let loadingView = UIBarButtonItem(customView: activityView)
        self.navigationItem.rightBarButtonItem = loadingView
    }
    
    func configureRefreshButton() {
        let refreshButton = UIBarButtonItem(barButtonSystemItem: .Refresh, target: self, action: "forceSyncAction:")
        self.navigationItem.rightBarButtonItem = refreshButton
    }
    
    
    @IBAction func forceSyncAction(sender: UIBarButtonItem) {
        sender.enabled = false
        SyncManager.sharedInstance().sync {
            started in
            if !started {
                sender.enabled = true
            }
        }
    }
    
    @IBAction func zoomToShowAllLocationsAction(sender: UIButton) {
        if referenceLocationsFetchedResultsController != nil {
            if let locations = referenceLocationsFetchedResultsController.fetchedObjects as? [CDLocation] {
                mapView.zoomToFitCoordenables(locations as NSArray, animated: true)
                reloadSelectedReferenceLocationsFromMap()
            }
        }
    }
    
    @IBAction func zoomRoShowAllReferencesAction(sender: UIButton) {
        removeExistingLocationAnnotationsFromMap()
        if let references = fetchedResultsController.fetchedObjects as? [CDReference] {
            mapView.zoomToFitCoordenables(references as NSArray, animated: true)
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
        
        let pinAnnotation = annotation as! PinAnnotation
        
        var annotationView: MKAnnotationView!
        
        if pinAnnotation.model == CDReference.ModelName {
            // is a reference
            var pinAnnotationView: MKPinAnnotationView! = mapView.dequeueReusableAnnotationViewWithIdentifier(ReferencePinReusableAnnotationId) as? MKPinAnnotationView
            if pinAnnotationView != nil {
                pinAnnotationView.annotation = annotation
            } else {
                pinAnnotationView = MKPinAnnotationView(annotation: annotation, reuseIdentifier: ReferencePinReusableAnnotationId)
                pinAnnotationView.animatesDrop = false
            }
            annotationView = pinAnnotationView
        } else {
            // is a location
            let existingAnnotationView = mapView.dequeueReusableAnnotationViewWithIdentifier(LocationPinReusableAnnotationId)
            
            if existingAnnotationView != nil {
                existingAnnotationView.annotation = annotation
                annotationView = existingAnnotationView
            } else {
                annotationView = MKAnnotationView(annotation: annotation, reuseIdentifier: LocationPinReusableAnnotationId)
            }
        }
        
        configureAnnotationView(annotationView)
        
        let detailButton: UIButton = UIButton.buttonWithType(UIButtonType.DetailDisclosure) as! UIButton
        detailButton.setImage(UIImage(named: "getin"), forState: UIControlState.Normal)
        annotationView.rightCalloutAccessoryView = detailButton
        
        // Only the reference has teh action sheet
        if pinAnnotation.model == CDReference.ModelName {
            let otherButton: UIButton = UIButton.buttonWithType(UIButtonType.DetailDisclosure) as! UIButton
            otherButton.setImage(UIImage(named: "gear"), forState: UIControlState.Normal)
            annotationView.leftCalloutAccessoryView = otherButton
        }
        
        return annotationView
    }
    
    func mapView(mapView: MKMapView!, didSelectAnnotationView view: MKAnnotationView!) {
        let pinAnnotation = view.annotation as! PinAnnotation
        
        if pinAnnotation.model == CDReference.ModelName {
            logger.debug("New pin selected")
            self.selectReferencePinAndReloadLocations(pinAnnotation)
            selectedReferencePinAnnotation = pinAnnotation
            selectedLocationPinAnnotation = nil
        } else {
            selectedLocationPinAnnotation = pinAnnotation
        }
    }
    
    func mapView(mapView: MKMapView!, annotationView view: MKAnnotationView!, calloutAccessoryControlTapped control: UIControl!) {
        let annotation = view.annotation as! PinAnnotation
        if control == view.rightCalloutAccessoryView {
            
            if annotation.model == CDReference.ModelName {
                selectedReferencePinAnnotation = annotation
            } else {
                selectedLocationPinAnnotation = annotation
            }
            
            performSegueWithIdentifier(ReferenceLocationSelectedSegueId, sender: self)
//            if annotation.model == CDReference.ModelName {
//                // Mark the selected location to use it while preparing for segue
//                
//            } else if annotation.model == CDLocation.ModelName {
//                // TODO: Segue to images at location
//                
//                
//                
//            }
        } else if control == view.leftCalloutAccessoryView {

            if annotation.model == CDReference.ModelName {
                // Mark the selected location to use it while preparing for segue
                let reference = self.sharedContext.objectWithID(annotation.objectID) as! CDReference
                self.showReferenceActionSheet(reference) {
                    // TODO: Move this to a service class
                    self.sharedContext.deleteObject(reference)
                    CoreDataStackManager.sharedInstance().saveContext { hadChanges in
                        self.deselectCurrentPinAndRemoveLocations()
                    }
                }
            }
            
           
        }
    }
    
    func deselectCurrentPinAndRemoveLocations() {
        selectedReferencePinAnnotation = nil
        selectedLocationPinAnnotation = nil
        removeExistingLocationAnnotationsFromMap()
    }
    
    func selectReferencePinAndReloadLocations(pinAnnotation: PinAnnotation) {
        selectedReferencePinAnnotation = pinAnnotation
        
        referenceLocationsFetchedResultsController = setupReferenceLocationsFetchedResultsController()!
        var error: NSError?
        referenceLocationsFetchedResultsController.performFetch(&error)
        if let error = error {
            logger.error("Error fetching locations for reference: \(error.localizedDescription)")
        }
        
        reloadSelectedReferenceLocationsFromMap()
    }
    
    // TODO: Move
    
    
    
    
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
            
            if selectedReferencePinAnnotation != nil {
                destination.selectedReference = sharedContext.objectWithID(selectedReferencePinAnnotation.objectID) as! CDReference
            }
            if selectedLocationPinAnnotation != nil {
                destination.selectedLocation = sharedContext.objectWithID(selectedLocationPinAnnotation.objectID) as! CDLocation
            }
            
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
        
        if selectedReferencePinAnnotation != nil {
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
            
            if selectedReferencePinAnnotation != nil && pinAnnotation == selectedReferencePinAnnotation {
                removeExistingLocationAnnotationsFromMap()
            }
            
        } else {
            logger.error("Delete called on unexisting pin annotation")
        }
    }
    
    func fetchedResultsChangeUpdate(reference: CDReference) {
        fetchedResultsChangeDelete(reference)
        let insertedPin = fetchedResultsChangeInsert(reference)
        
        if selectedReferencePinAnnotation != nil && insertedPin.objectID == selectedReferencePinAnnotation.objectID {
            mapView.selectAnnotation(insertedPin, animated: false)
        }
        
    }
    
    func fetchedResultsChangeMove(reference: CDReference) {
        // FIXME: Is this even called?
    }
    
    func configureAnnotationView(annotationView: MKAnnotationView) {
        let pinAnnotation = annotationView.annotation as! PinAnnotation
        
        if pinAnnotation.model == CDReference.ModelName {
            // Is a reference
            
            let reference = sharedContext.objectWithID(pinAnnotation.objectID) as! CDReference
            
            let referenceLocationCount = reference.locationList.count
            let withMediaCount = reference.countNonEmptyLocations()
            
            pinAnnotation.title = reference.name
            pinAnnotation.subtitle = "\(withMediaCount) locations"
            
            let pinAnnotationView = annotationView as! MKPinAnnotationView
            
            if reference.state == CDReferenceState.WithLocations.rawValue {
                pinAnnotationView.pinColor = MKPinAnnotationColor.Purple
                pinAnnotationView.draggable = true
                pinAnnotationView.canShowCallout = true
            } else if reference.state == CDReferenceState.New.rawValue {
                pinAnnotationView.draggable = false
                pinAnnotationView.canShowCallout = false
                pinAnnotationView.pinColor = MKPinAnnotationColor.Red
            } else {
                // Ready
                pinAnnotationView.pinColor = MKPinAnnotationColor.Green
                pinAnnotationView.draggable = true
                pinAnnotationView.canShowCallout = true
            }
        } else {
            // Is a location
            let location = sharedContext.objectWithID(pinAnnotation.objectID) as! CDLocation
            pinAnnotation.title = location.name
            pinAnnotation.subtitle = location.subtitle
            
            
            var image: UIImage!
            if location.locationType == CDLocationType.Instagram.rawValue {
                image = UIImage(named: "MiniInstagram")
            } else {
                image = UIImage(named: "MiniFoursquare")
                
            }
            
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
        if selectedReferencePinAnnotation != nil {
            let reference = sharedContext.objectWithID(selectedReferencePinAnnotation.objectID) as! CDReference
            return reference
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
