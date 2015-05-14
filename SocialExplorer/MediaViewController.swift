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

class MediaViewController: UIViewController, MKMapViewDelegate {
    
    let MediaReusableAnnotationId = "MediaReusableAnnotation"
    
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var descriptionLabel: UILabel!
    @IBOutlet weak var imageView: UIImageView!
    @IBOutlet weak var starButton: UIButton!
    @IBOutlet weak var mapView: MKMapView!
    @IBOutlet weak var hearthButton: UIButton!
    
    var mediaLiked: Bool?
    
    var sharedContext: NSManagedObjectContext!
    
    var mediaSelected: CDMedia!
    
    var instagramClient = InstagramClient()
    
    // MARK: - View life cycle
    
    override func viewDidLoad() {
        super.viewDidLoad()        
        
        // shared context
        sharedContext = CoreDataStackManager.sharedInstance().managedObjectContext
        
        titleLabel.text = mediaSelected.title
        descriptionLabel.text = mediaSelected.tagsAsCommaSeparatedString()
        
        
        
        // FIXME
        self.setupMediaLiked()
        
        
        let url = NSURL(string: mediaSelected.imageURL)!
        imageView.hnk_setImageFromURL(url, format: Format<UIImage>(name: "original")) {
            (image) -> () in
            self.imageView.image = image            
        }
        
        mapView.delegate = self
        
        let pinAnnotation = PinAnnotation(objectID: mediaSelected.objectID, coordinate: mediaSelected.coordinate, model: CDMedia.ModelName)
        
        self.navigationItem.title = mediaSelected.parentLocation.title
        
        // TODO: Arrange this in a common place
        let span = MKCoordinateSpan(latitudeDelta: 0.004, longitudeDelta: 0.004)
        let region = MKCoordinateRegion(center: pinAnnotation.coordinate, span: span)
        mapView.setRegion(region, animated: false)
        mapView.addAnnotation(pinAnnotation)
        
//        mapView.selectAnnotation(pinAnnotation, animated: false)
        
        updateStarButton()
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        
        
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
            // TODO: named: with contants
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
                image = UIImage(named: "heart-red")
            } else {
                image = UIImage(named: "heart")
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
        
        //        let detailButton: UIButton = UIButton.buttonWithType(UIButtonType.DetailDisclosure) as! UIButton
        //        annotationView.rightCalloutAccessoryView = detailButton
        
        return annotationView
    }
    
    func configurePin(annotationView: MKAnnotationView) {
        // TODO: This should be in a class
        
        var image: UIImage!
        // FIXME
        if mediaSelected.parentLocation.locationType == CDLocationType.Instagram.rawValue {
            image = UIImage(named: "MiniInstagram")
        } else {
            image = UIImage(named: "MiniFoursquare")
        }
       
        
        annotationView.image = image
        annotationView.canShowCallout = true
    }
    
    
    // MARK: Utils
    
    func updateStarButton() {
        if self.mediaSelected.isFavorited() {
            self.starButton.setImage(UIImage(named: "star-highlighted"), forState: .Normal)
        } else {
            self.starButton.setImage(UIImage(named: "star"), forState: .Normal)
        }
    }
}