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

class MediaViewController: UIViewController {
    
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var descriptionLabel: UILabel!
    @IBOutlet weak var imageView: UIImageView!
    @IBOutlet weak var starButton: UIButton!
    
    var sharedContext: NSManagedObjectContext!
    
    var mediaSelected: CDMedia!
    
    override func viewDidLoad() {
        super.viewDidLoad()        
        
        // shared context
        sharedContext = CoreDataStackManager.sharedInstance().managedObjectContext
        
        titleLabel.text = mediaSelected.title
        
        descriptionLabel.text = mediaSelected.tagsAsCommaSeparatedString()
        
        let url = NSURL(string: mediaSelected.standardResolutionURL)!
        imageView.hnk_setImageFromURL(url, format: Format<UIImage>(name: "original")) {
            (image) -> () in
            self.imageView.image = image            
        }
        
        updateStarButton()
    }
    
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
    
    func updateStarButton() {
        if self.mediaSelected.isFavorited() {
            self.starButton.setImage(UIImage(named: "star-highlighted"), forState: .Normal)
        } else {
            self.starButton.setImage(UIImage(named: "star"), forState: .Normal)
        }
    }
}