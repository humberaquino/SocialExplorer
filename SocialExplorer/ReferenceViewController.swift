//
//  InterestingLocationViewController.swift
//  SocialExplorer
//
//  Created by Humberto Aquino on 5/5/15.
//  Copyright (c) 2015 Humberto Aquino. All rights reserved.
//

import Foundation
import UIKit
import MapKit
import CoreData

class ReferenceViewController: UIViewController, MKMapViewDelegate, NSFetchedResultsControllerDelegate, UITableViewDataSource, UITableViewDelegate {
    
    let LocationReusableAnnotationId = "LocationReusableAnnotationId"
    let MediaDetailSegueId = "MediaDetailSegue"
    
    let userSettings = UserSettings.sharedInstance()
    
    @IBOutlet weak var mapView: MKMapView!
    
    @IBOutlet weak var tableView: UITableView!
    
    @IBOutlet weak var searchOptionSegmentControl: UISegmentedControl!
    
    var sharedContext: NSManagedObjectContext!
    
    var selectedReference: CDReference!
    var selectedLocation: CDLocation!
    var selectedMedia: CDMedia!
    
    var tapRecognizer: UITapGestureRecognizer!
    
    var annotationProgrammaticallySelected: Bool = false
    
    // MARK: - View life cycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Initialize Core Data
        sharedContext = CoreDataStackManager.sharedInstance().managedObjectContext
        
        // Delegate setup
        mapView.delegate = self
        tableView.delegate = self
        tableView.dataSource = self
        
        tapRecognizer = UITapGestureRecognizer(target: self, action: "handleTapOnMapGesture:")             
        
        updateFetchedResultsControllers()
//        reloadAnnotationsToMapViewFromFetchedResults()
        
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        // Remove all annotations
        mapView.addGestureRecognizer(tapRecognizer)
//        mapView.removeAnnotations(mapView.annotations)                                
        
    }
    
    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(animated)
        
//        let region = MKCoordinateRegion(center: selectedReference.coordinate, span: selectedReference.span)
//        mapView.setRegion(region, animated: true)
        
        reloadAnnotationsToMapViewFromFetchedResults()
        
        
        if selectedLocation != nil {
            mapView.selectAnnotation(selectedLocation, animated: true)
            //            selectFirstMediaInLocation(selectedLocation)
        }
        
//        mapView.addAnnotation(selectedReference)
    }
    
    override func viewWillDisappear(animated: Bool) {
        super.viewWillDisappear(animated)
        mapView.removeGestureRecognizer(tapRecognizer)
        saveMapViewRegion()
    }
    
    func updateFetchedResultsControllers() {
        // TODO: Handle the error with a alertview
        // Do the initial fetch
        reloadLocationFetchedResultsController()
        var error: NSError?
        locationFetchedResultsController.performFetch(&error)
        
        if let error = error {
            logger.error("Error performing initial fetch: \(error)")
        }
        
        // Fetch media
        reloadMediaFetchedResultsController()
        error = nil
        mediaFetchedResultsController.performFetch(&error)
        if let error = error {
            logger.error("Error performing initial fetch fot media: \(error)")
        }
        
        tableView.reloadData()
    }
    
    func handleTapOnMapGesture(recognizer: UIGestureRecognizer) {
        logger.debug("Tap on map")
    }
    
    // MARK: - MKMapViewDelegate
    
//    func mapView(mapView: MKMapView!, regionDidChangeAnimated animated: Bool) {
//        saveMapViewRegion(mapView)
//    }
//    
    
    // MARK: - NSFetchedResultsControllerDelegate
    
    
    func controller(controller: NSFetchedResultsController, didChangeObject anObject: AnyObject, atIndexPath indexPath: NSIndexPath?, forChangeType type: NSFetchedResultsChangeType, newIndexPath: NSIndexPath?) {
        
        
        if anObject is CDMedia {
            // TODO: Refactor
            switch type {
            case .Insert:
                self.tableView.insertRowsAtIndexPaths([newIndexPath!], withRowAnimation: .Fade)
            case .Update:
                let cell = self.tableView.cellForRowAtIndexPath(indexPath!) as! MediaTableViewCell
                self.configureCell(cell, atIndexPath: indexPath!)

                self.tableView.reloadRowsAtIndexPaths([indexPath!], withRowAnimation: UITableViewRowAnimation.Fade)
            case .Move:
                self.tableView.deleteRowsAtIndexPaths([indexPath!], withRowAnimation: UITableViewRowAnimation.Fade)
                self.tableView.insertRowsAtIndexPaths([newIndexPath!], withRowAnimation: UITableViewRowAnimation.Fade)
            case .Delete:
                self.tableView.deleteRowsAtIndexPaths([indexPath!], withRowAnimation: UITableViewRowAnimation.Fade)
            default:
                return
            }
        } else if anObject is MKAnnotation {
            let annotation = anObject as! MKAnnotation
            switch type {
            case .Insert:
                fetchedResultsChangeInsert(annotation)
                break
            case .Delete:
                fetchedResultsChangeDelete(annotation)
                break
            case .Update:
                fetchedResultsChangeUpdate(annotation)
                break
            case .Move:
                
                break
            }
        }
        
    }
    func controllerWillChangeContent(controller: NSFetchedResultsController) {
        self.tableView.beginUpdates()
    }
    func controllerDidChangeContent(controller: NSFetchedResultsController) {
        self.tableView.endUpdates()
    }
    
    // MARK: - MKMapViewDelegate
    
    func mapView(mapView: MKMapView!, viewForAnnotation annotation: MKAnnotation!) -> MKAnnotationView! {
        var annotationView = mapView.dequeueReusableAnnotationViewWithIdentifier(LocationReusableAnnotationId)
        
        
        if annotationView != nil {
            annotationView.annotation = annotation
        } else {
            annotationView = MKPinAnnotationView(annotation: annotation, reuseIdentifier: LocationReusableAnnotationId)
            
        }
        
        configurePin(annotationView)
        
//        let detailButton: UIButton = UIButton.buttonWithType(UIButtonType.DetailDisclosure) as! UIButton
//        annotationView.rightCalloutAccessoryView = detailButton
        
        return annotationView
    }
    
    
    func mapView(mapView: MKMapView!, annotationView view: MKAnnotationView!, didChangeDragState newState: MKAnnotationViewDragState, fromOldState oldState: MKAnnotationViewDragState) {
        if newState == MKAnnotationViewDragState.Ending {
            let selectedReference = view.annotation as! CDReference
            
            logger.debug("coord: \(selectedReference.coordinate)")
            
            selectedReference.markAsNew()
            
            CoreDataStackManager.sharedInstance().saveContext { hasChanged in
                
                SyncManager.sharedInstance().sync()
            }
        }
    }
    
    func mapView(mapView: MKMapView!, didSelectAnnotationView view: MKAnnotationView!) {
        let location = view.annotation as! CDLocation
         logger.debug("Annotation selected")
        
        self.selectFirstMediaInLocation(location)
      
    }
    
    func selectFirstMediaInLocation(location: CDLocation) {
        if let firstObject = location.mediaList.firstObject as? CDMedia {
            if let indexPath = mediaFetchedResultsController.indexPathForObject(firstObject) {
                if !annotationProgrammaticallySelected {
                    tableView.scrollToRowAtIndexPath(indexPath, atScrollPosition: .Top, animated: true)
                }
            }
        }
        // FIXME
        annotationProgrammaticallySelected = false
    }
    
    func scrollViewDidEndDragging(scrollView: UIScrollView, willDecelerate decelerate: Bool) {
         println("----- End scroling")
        if let visibleIndexPaths = tableView.indexPathsForVisibleRows() as? [NSIndexPath] {
            if visibleIndexPaths.count > 0 {
                let indexPath = visibleIndexPaths[0]
                let topMedia = mediaFetchedResultsController.objectAtIndexPath(indexPath) as! CDMedia
                
                annotationProgrammaticallySelected = true
                mapView.selectAnnotation(topMedia.parentLocation, animated: true)
                logger.debug("Current location: \(topMedia.parentLocation.name)")
                
            }
        }
    }
    
    
    func configurePin(annotationView: MKAnnotationView) {
       
        let location = annotationView.annotation as! CDLocation
                
        var image: UIImage!
        // FIXME
        if location.locationType == SocialNetworkType.Instagram.rawValue {
            image = UIImage(named: "MiniInstagram")
        } else {
            image = UIImage(named: "MiniFoursquare")
        }
        
        annotationView.image = image
        annotationView.canShowCallout = true
        let annotation = annotationView.annotation as! CDLocation
        if annotation.mediaList.count == 0 {
            annotationView.alpha = 0.5
        } else {
            annotationView.alpha = 1.0
        }
    }
    
    
    // MARK: NSFetchedResultsControllerDelegate utils
    
    func fetchedResultsChangeInsert(annotation: MKAnnotation) {
        mapView.addAnnotation(annotation)
    }
    
    func fetchedResultsChangeDelete(annotation: MKAnnotation) {
        mapView.removeAnnotation(annotation)
    }
    
    func fetchedResultsChangeUpdate(annotation: MKAnnotation) {
        fetchedResultsChangeDelete(annotation)
        fetchedResultsChangeInsert(annotation)
    }
    
    
    // MARK: UITableViewDelegate

    func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        
        if let media = mediaFetchedResultsController.objectAtIndexPath(indexPath) as? CDMedia {
            selectedMedia = media
            performSegueWithIdentifier(MediaDetailSegueId, sender: self)
        }
    }
    
    // MARK: UITableViewDataSource
    
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        let info = self.mediaFetchedResultsController.sections![section] as! NSFetchedResultsSectionInfo
        return info.numberOfObjects
    }
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        // To mix cell types http://stackoverflow.com/questions/1405688/2-different-types-of-custom-uitableviewcells-in-uitableview
        let cell = tableView.dequeueReusableCellWithIdentifier("MediaCell", forIndexPath: indexPath) as! MediaTableViewCell
        self.configureCell(cell, atIndexPath: indexPath)
        return cell
    }
    
    func configureCell(cell: MediaTableViewCell, atIndexPath indexPath: NSIndexPath) {
        let media = self.mediaFetchedResultsController.objectAtIndexPath(indexPath) as! CDMedia

        cell.configureUsingMedia(media)
        
    }
    
    // MARK: Segue
    
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        if segue.identifier == MediaDetailSegueId {
            let destination = segue.destinationViewController as! MediaViewController
            destination.mediaSelected = selectedMedia
        }
    }
    
    
    // MARK: Utils    
    
    // Utility method to start a fresh mapview
    func reloadAnnotationsToMapViewFromFetchedResults() {
        let annotations = mapView.annotations
        mapView.removeAnnotations(annotations)
        mapView.addAnnotations(locationFetchedResultsController.fetchedObjects)
        
//        mapView.addAnnotation(selectedReference)
        
        mapView.zoomToFitCurrentCoordenables(false)
    }
    
    @IBAction func segmentChanged(sender: UISegmentedControl) {
        logger.debug("Segment: \(sender)")
        
        updateFetchedResultsControllers()
        reloadAnnotationsToMapViewFromFetchedResults()
    
    }
    
    @IBAction func optionsAction(sender: UIBarButtonItem) {
        
        self.showReferenceActionSheet(selectedReference) {
            self.sharedContext.deleteObject(self.selectedReference)
//            self.dismissViewControllerAnimated(true, completion: nil)
//            self.navigationController?.popToRootViewControllerAnimated(true)
            self.navigationController?.popViewControllerAnimated(true)
        }
        
    }
    
    var mediaFetchedResultsController:NSFetchedResultsController!
    func reloadMediaFetchedResultsController (){
        
        let fetchRequest = NSFetchRequest(entityName: CDMedia.ModelName)
        
        let referencePredicate = NSPredicate(format: "parentLocation.referenceList contains[c] %@", self.selectedReference)
        
        if let current = self.currentNetwork() {
            let socialPredicate = NSPredicate(format: "%K = %@", CDMedia.PropertyKeys.Type, current.rawValue)
            fetchRequest.predicate = NSCompoundPredicate(type: NSCompoundPredicateType.AndPredicateType, subpredicates: [socialPredicate, referencePredicate])
        } else {
            // Search all
            fetchRequest.predicate = referencePredicate
        }
        
        
        let sortDescriptor = NSSortDescriptor(key: "parentLocation.id", ascending: true)
        fetchRequest.sortDescriptors = [sortDescriptor]
        
        let fetchedResultsController = NSFetchedResultsController(fetchRequest: fetchRequest, managedObjectContext: self.sharedContext, sectionNameKeyPath: nil, cacheName: nil)
        fetchedResultsController.delegate = self
        
        mediaFetchedResultsController = fetchedResultsController
    }
    
    var locationFetchedResultsController: NSFetchedResultsController!
    func reloadLocationFetchedResultsController() {
        
        let fetchRequest = NSFetchRequest(entityName: CDLocation.ModelName)
        
        let referenceListPredicate = NSPredicate(format: "%K contains[c] %@", CDLocation.Keys.ReferenceList, self.selectedReference)
        
        let mediaListNonEmptyPredicate = NSPredicate(format: "mediaList.@count > 0")
        
        
        var predicates:[NSPredicate] = [referenceListPredicate, mediaListNonEmptyPredicate]
        
        if let current = self.currentNetwork() {
            let socialPredicate = NSPredicate(format: "%K = %@", CDLocation.Keys.LocationType, current.rawValue)
            predicates.append(socialPredicate)
        }
        
        fetchRequest.predicate = NSCompoundPredicate(type: NSCompoundPredicateType.AndPredicateType, subpredicates: predicates)
        
        
        fetchRequest.sortDescriptors = []
        
        let fetchedResultsController = NSFetchedResultsController(fetchRequest: fetchRequest, managedObjectContext: self.sharedContext, sectionNameKeyPath: nil, cacheName: nil)
        fetchedResultsController.delegate = self
        
        locationFetchedResultsController = fetchedResultsController
    }
    

    // FIXME
//    func searchAllNetworks() -> Bool {
//        if let current = currentNetwork () {
//            return false
//        } else {
//            return true
//        }
//    }
    
    
    func currentNetwork() -> SocialNetworkType? {
        switch self.searchOptionSegmentControl.selectedSegmentIndex {
        case 1:
            return SocialNetworkType.Instagram
        case 2:
            return SocialNetworkType.Foursquare
        default:
            return nil
        }
    }
    
    func saveMapViewRegion() {
        logger.debug("Saving new location span")
        selectedReference.span = mapView.region.span
        CoreDataStackManager.sharedInstance().saveContext()
    }
}


// TODO: Move this extension
// Ref: http://stackoverflow.com/a/7200744/223228
extension MKMapView {
    
    func zoomToFitCurrentCoordenables(animated: Bool) {
        let locations = self.annotations as NSArray
        zoomToFitCoordenables(locations, animated: animated)
    }
    
    
    func zoomToFitCoordenables(coordenables: NSArray, animated: Bool) {
        if coordenables.count == 0 {
            return
        }
        
        var topLeftCoord = CLLocationCoordinate2D(latitude: -90, longitude: 180)
        var bottomRightCoord = CLLocationCoordinate2D(latitude: 90, longitude: -180)
        
//        let locations = self.annotations as NSArray
        
        for element in coordenables {
            let location = element as! Coordenable
            topLeftCoord.longitude = fmin(topLeftCoord.longitude, location.coordinate.longitude)
            topLeftCoord.latitude = fmax(topLeftCoord.latitude, location.coordinate.latitude)
            bottomRightCoord.longitude = fmax(bottomRightCoord.longitude, location.coordinate.longitude)
            bottomRightCoord.latitude = fmin(bottomRightCoord.latitude, location.coordinate.latitude)
        }
        
        let latitude = topLeftCoord.latitude - (topLeftCoord.latitude - bottomRightCoord.latitude) * 0.5
        let longitude = topLeftCoord.longitude + (bottomRightCoord.longitude - topLeftCoord.longitude) * 0.5
        
        let center = CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
        
        // Add extra padding
        let longitudeDelta = fabs(bottomRightCoord.longitude - topLeftCoord.longitude) * 1.1
        let latitudeDelta = fabs(topLeftCoord.latitude - bottomRightCoord.latitude) * 1.6
        let span = MKCoordinateSpan(latitudeDelta: latitudeDelta, longitudeDelta: longitudeDelta)
        
        var region = MKCoordinateRegion(center: center, span: span)
        
        region = self.regionThatFits(region)
        
        self.setRegion(region, animated:animated)
    }
}

