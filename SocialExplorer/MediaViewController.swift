//
//  MediaViewController.swift
//  SocialExplorer
//
//  Created by Humberto Aquino on 5/11/15.
//  Copyright (c) 2015 Humberto Aquino. All rights reserved.
//

import Foundation
import UIKit
import Haneke
import CoreData
import MapKit


// Represents a single media that is displayed to the user
class MediaViewController: UIViewController, MKMapViewDelegate {
    
    let MediaReusableAnnotationId = "MediaReusableAnnotation"
    
    let MediaDelta = 0.004
    
    @IBOutlet weak var dateLabel: UILabel!
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var descriptionLabel: UILabel!
    @IBOutlet weak var imageView: UIImageView!
    @IBOutlet weak var starButton: UIButton!
    @IBOutlet weak var mapView: MKMapView!
    @IBOutlet weak var hearthButton: UIButton!
    
    var mediaLiked: Bool?
    
    // Core data main context
    var sharedContext: NSManagedObjectContext!
    
    // The selected media
    var mediaSelected: CDMedia!
    
    // Client used to check if the image is liked or not
    var instagramClient = InstagramClient()
    
    
    // MARK: - View life cycle
    
    override func viewDidLoad() {
        super.viewDidLoad()        
        
        // shared context
        sharedContext = CoreDataStackManager.sharedInstance().managedObjectContext
        
        titleLabel.text = mediaSelected.title
        descriptionLabel.text = mediaSelected.tagsAsCommaSeparatedString()
        
        // The date the media was created
        if let date = mediaSelected.creationDate {
            let formatter = NSDateFormatter()
            formatter.dateFormat = "MM-dd-yyyy HH:mm"
            var dateString = formatter.stringFromDate(date)
            dateLabel.text = dateString
        } else {
            dateLabel.hidden = true
        }
        
        // For instagram media, check if is liked
        if mediaSelected.parentLocation.isInstagramLocation() {
            self.setupMediaLiked()
        }
        
        // Delegates
        mapView.delegate = self
        
        setupMediaImage()
        
        // Update the title
        self.navigationItem.title = mediaSelected.parentLocation.title
        
        setupPinIntoMap()
        
        updateStarButton()
    }
    
    func setupMediaImage() {
        let url = NSURL(string: mediaSelected.imageURL)!
        imageView.hnk_setImageFromURL(url, format: Format<UIImage>(name: "original")) {
            (image) -> () in
            self.imageView.image = image
        }
    }
    
    func setupPinIntoMap() {
        let pinAnnotation = PinAnnotation(objectID: mediaSelected.objectID, coordinate: mediaSelected.coordinate, model: CDMedia.ModelName)
        
        let span = MKCoordinateSpan(latitudeDelta: MediaDelta, longitudeDelta: MediaDelta)
        let region = MKCoordinateRegion(center: pinAnnotation.coordinate, span: span)
        mapView.setRegion(region, animated: false)
        mapView.addAnnotation(pinAnnotation)
    }
    
    
    // MARK: - Actions
    
    @IBAction func favoriteAction(sender: UIButton) {
        mediaSelected.toogleFavorited()
        
        var error: NSError?
        sharedContext.save(&error)
        if let error = error {
            logger.error("Error while marking as favorite")
        }
        
        CoreDataStackManager.sharedInstance().saveContext { hasChanged in
            self.updateStarButton()
        }
        
    }
    
    func setupMediaLiked() {
        instagramClient.isMediaLiked(mediaSelected.id) { (isLiked, error) in
            if let error = error {
                self.showMessageWithTitle("Could not get the media info", message: error.localizedDescription)
                return
            }
            var image: UIImage!
            if isLiked {
                image = UIImage(named: ImageName.HeartRed)
            } else {
                image = UIImage(named: ImageName.Heart)
            }
            self.hearthButton.imageView?.image = image
            self.hearthButton.hidden = false
        }
    }
    
    // MARK: - MKMapViewDelegate
    
    func mapView(mapView: MKMapView!, viewForAnnotation annotation: MKAnnotation!) -> MKAnnotationView! {
        var annotationView = mapView.dequeueReusableAnnotationViewWithIdentifier(MediaReusableAnnotationId)
        if annotationView != nil {
            annotationView.annotation = annotation
        } else {
            annotationView = MKPinAnnotationView(annotation: annotation, reuseIdentifier: MediaReusableAnnotationId)            
        }
        configurePin(annotationView)
        return annotationView
    }
    
    func configurePin(annotationView: MKAnnotationView) {
        var image: UIImage!
        if mediaSelected.parentLocation.locationType == SocialNetworkType.Instagram.rawValue {
            image = UIImage(named: ImageName.MiniInstagram)
        } else {
            image = UIImage(named: ImageName.MiniFoursquare)
        }
        annotationView.image = image
        annotationView.canShowCallout = true
    }
    
    
    // MARK: Utils
    
    func updateStarButton() {
        if self.mediaSelected.isFavorited() {
            self.starButton.setImage(UIImage(named: ImageName.StarHighlighted), forState: .Normal)
        } else {
            self.starButton.setImage(UIImage(named: ImageName.Star), forState: .Normal)
        }
    }
}