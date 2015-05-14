//
//  MediaTableViewCell.swift
//  SocialExplorer
//
//  Created by Humberto Aquino on 5/11/15.
//  Copyright (c) 2015 Humberto Aquino. All rights reserved.
//

import Foundation
import UIKit
import Haneke

// Cell used to show a media in a table
class MediaTableViewCell: UITableViewCell {
    
    @IBOutlet weak var tumbnailImageView: UIImageView!
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var detailLabel: UILabel!
    @IBOutlet weak var locationLabel: UILabel!    
    @IBOutlet weak var starButton: UIButton!

    var mediaSelected: CDMedia!
    
    func configureUsingMedia(media: CDMedia) {
        mediaSelected = media
        
        titleLabel.text = media.title
        detailLabel.text = media.detail
        locationLabel.text = media.parentLocation.name

        let url = NSURL(string: media.thumbnailURL)!
        tumbnailImageView?.hnk_setImageFromURL(url, format: Format<UIImage>(name: "original"), success:{
            image in
            self.tumbnailImageView?.image = image
            self.setNeedsDisplay()
        })
        
        updateStarButton()
    }
    
    @IBAction func startPressedAction(sender: UIButton) {
        mediaSelected.toogleFavorited()
        
        // shared context
        var sharedContext = CoreDataStackManager.sharedInstance().managedObjectContext!
        
        var error: NSError?
        sharedContext.save(&error)
        if let error = error {
            logger.error("Error while marking as favorite")
        }
        
        CoreDataStackManager.sharedInstance().saveContext { hasChanged in
            self.updateStarButton()
        }
    }
    
    func updateStarButton() {
        if self.mediaSelected.isFavorited() {
            self.starButton.setImage(UIImage(named: ImageName.StarHighlighted), forState: .Normal)
        } else {
            self.starButton.setImage(UIImage(named: ImageName.Star), forState: .Normal)
        }
    }
}