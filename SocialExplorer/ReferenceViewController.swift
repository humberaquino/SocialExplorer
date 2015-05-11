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

class ReferenceViewController: UIViewController, MKMapViewDelegate, NSFetchedResultsControllerDelegate {
    
    let LocationReusableAnnotationId = "LocationReusableAnnotationId"
    
    let userSettings = UserSettings.sharedInstance()
    
    @IBOutlet weak var mapView: MKMapView!
    
    var sharedContext: NSManagedObjectContext!
    
    var selectedReference: CDReference!
    
    // MARK: - View life cycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Initialize Core Data
        sharedContext = CoreDataStackManager.sharedInstance().managedObjectContext
        
        // Delegate setup
        mapView.delegate = self
        
        // TODO: Handle the error with a alertview
        // Do the initial fetch
        var error: NSError?
        fetchedResultsController.performFetch(&error)
        
        if let error = error {
            logger.error("Error performing initial fetch: \(error)")
        }
        
//        reloadAnnotationsToMapViewFromFetchedResults()
        
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        // Remove all annotations
//        mapView.removeAnnotations(mapView.annotations)                                
        
    }
    
    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(animated)
        
//        let region = MKCoordinateRegion(center: selectedReference.coordinate, span: selectedReference.span)
//        mapView.setRegion(region, animated: true)
        
        reloadAnnotationsToMapViewFromFetchedResults()
        
//        mapView.addAnnotation(selectedReference)
    }
    
    override func viewWillDisappear(animated: Bool) {
        super.viewWillDisappear(animated)
        saveMapViewRegion()
    }
    
    // MARK: - MKMapViewDelegate
    
//    func mapView(mapView: MKMapView!, regionDidChangeAnimated animated: Bool) {
//        saveMapViewRegion(mapView)
//    }
//    
    
    // MARK: - NSFetchedResultsControllerDelegate
    
    
    func controller(controller: NSFetchedResultsController, didChangeObject anObject: AnyObject, atIndexPath indexPath: NSIndexPath?, forChangeType type: NSFetchedResultsChangeType, newIndexPath: NSIndexPath?) {
        
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
    
    // MARK: - MKMapViewDelegate
    
    func mapView(mapView: MKMapView!, viewForAnnotation annotation: MKAnnotation!) -> MKAnnotationView! {
        var annotationView:MKPinAnnotationView! = mapView.dequeueReusableAnnotationViewWithIdentifier(LocationReusableAnnotationId) as? MKPinAnnotationView
        
//        let reference = annotation as! CDReference
        
        if annotationView != nil {
            annotationView.annotation = annotation
        } else {
            annotationView = MKPinAnnotationView(annotation: annotation, reuseIdentifier: LocationReusableAnnotationId)
            annotationView.animatesDrop = true
        }
        
        configurePin(annotationView)
        
        let detailButton: UIButton = UIButton.buttonWithType(UIButtonType.DetailDisclosure) as! UIButton
        annotationView.rightCalloutAccessoryView = detailButton
        
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
    
    func configurePin(annotationView: MKPinAnnotationView) {
        let annotation = annotationView.annotation
        if annotation.isKindOfClass(CDReference.classForCoder()) {
            annotationView.pinColor = MKPinAnnotationColor.Green
            annotationView.draggable = true
        } else if annotation.isKindOfClass(CDLocation.classForCoder()) {
            annotationView.pinColor = MKPinAnnotationColor.Red
            annotationView.draggable = false
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
    
    // MARK: Utils    
    
    // Utility method to start a fresh mapview
    func reloadAnnotationsToMapViewFromFetchedResults() {
        let annotations = mapView.annotations
        mapView.removeAnnotations(annotations)
        mapView.addAnnotations(fetchedResultsController.fetchedObjects)
        
//        mapView.addAnnotation(selectedReference)
        
        mapView.zoomToFitLocationAnnotations()
    }
    
    lazy var fetchedResultsController: NSFetchedResultsController = {
        
        let fetchRequest = NSFetchRequest(entityName: CDLocation.ModelName)
        fetchRequest.predicate = NSPredicate(format: "%K contains[c] %@", CDLocation.Keys.ReferenceList, self.selectedReference)
        fetchRequest.sortDescriptors = []
        
        let fetchedResultsController = NSFetchedResultsController(fetchRequest: fetchRequest, managedObjectContext: self.sharedContext, sectionNameKeyPath: nil, cacheName: nil)
        fetchedResultsController.delegate = self
        
        return fetchedResultsController
        }()
    
    func saveMapViewRegion() {
        logger.debug("Saving new location span")
        selectedReference.span = mapView.region.span
        CoreDataStackManager.sharedInstance().saveContext()
    }
}


// Ref: http://stackoverflow.com/a/7200744/223228
extension MKMapView {
    func zoomToFitLocationAnnotations() {
        if self.annotations.count == 0 {
            return
        }
        
        var topLeftCoord = CLLocationCoordinate2D(latitude: -90, longitude: 180)
        var bottomRightCoord = CLLocationCoordinate2D(latitude: 90, longitude: -180)
        
        let locations = self.annotations as NSArray
        
        for element in locations {
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
        
        self.setRegion(region, animated:true)
    }
}

