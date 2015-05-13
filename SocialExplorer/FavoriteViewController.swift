//
//  FavoriteViewController.swift
//  SocialExplorer
//
//  Created by Humberto Aquino on 5/13/15.
//  Copyright (c) 2015 Humberto Aquino. All rights reserved.
//

import Foundation
import UIKit
import CoreData
import Haneke
import XCGLogger

class FavoriteViewController: UIViewController, UICollectionViewDataSource, UICollectionViewDelegate, NSFetchedResultsControllerDelegate {
    
    let NoFavorites = "No favorites"
    
    let MediaDetailSegueId = "MediaDetailSegue"
    
    
    let FavoriteCell = "FavoriteCell"
    let LocationSpanValue = 0.004
    
    // Keep the changes. We will keep track of insertions, deletions, and updates.
    var insertedIndexPaths: [NSIndexPath]!
    var deletedIndexPaths: [NSIndexPath]!
    var updatedIndexPaths: [NSIndexPath]!
    
    @IBOutlet weak var collectionView: UICollectionView!
    @IBOutlet weak var collectionCenteredLabel: UILabel!
    
    var sharedContext = CoreDataStackManager.sharedInstance().managedObjectContext!
    
    var mediaSelected: CDMedia!
    
    // Service layer to interact with Core Data and the photos
//    let photoService = PhotoService()
    
    // MARK: - View life cycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Start the fetched results controller
        var error: NSError?
        fetchedResultsController.performFetch(&error)
        
        if let error = error {
            println("Error performing initial fetch: \(error)")
        }
        
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        
        if let fetchedObjecs = fetchedResultsController.fetchedObjects {
            if fetchedObjecs.count == 0 {
                displayCenteredLabel(NoFavorites)
            } else {
                hideCenteredLabel()
            }
        }
    }
    
    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(animated)
    }
    
    // MARK: - UICollectionViewDataSource
    
    func collectionView(collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        let sectionInfo = self.fetchedResultsController.sections![section] as! NSFetchedResultsSectionInfo
        
        println("Number of cells: \(sectionInfo.numberOfObjects)")
        return sectionInfo.numberOfObjects
    }
    
    func numberOfSectionsInCollectionView(collectionView: UICollectionView) -> Int {
        return self.fetchedResultsController.sections?.count ?? 0
    }
    
    func collectionView(collectionView: UICollectionView, cellForItemAtIndexPath indexPath: NSIndexPath) -> UICollectionViewCell {
        
        let cell = collectionView.dequeueReusableCellWithReuseIdentifier(FavoriteCell, forIndexPath: indexPath) as! FavoriteCollectionViewCell
        
        self.configureCell(cell, atIndexPath: indexPath)
        
        return cell
    }
    
    func collectionView(collectionView: UICollectionView, didSelectItemAtIndexPath indexPath: NSIndexPath) {
        
        let cell = collectionView.cellForItemAtIndexPath(indexPath) as! FavoriteCollectionViewCell
        
        // Delete image
        let media = self.fetchedResultsController.objectAtIndexPath(indexPath) as! CDMedia
       
        // TODO: Segue to Detail
        mediaSelected = media

        performSegueWithIdentifier(MediaDetailSegueId, sender: self)
    }
    
    func configureCell(cell: FavoriteCollectionViewCell, atIndexPath indexPath: NSIndexPath) {
        
        let media = self.fetchedResultsController.objectAtIndexPath(indexPath) as! CDMedia
        if let url = NSURL(string: media.standardResolutionURL) {
            
            cell.imageView.hnk_setImageFromURL(url, format: Format<UIImage>(name: "original"), failure:{ error in
                logger.error(error!.localizedDescription)
            }, success:{
                image in
                cell.imageView.image = image
                cell.setNeedsDisplay()
            })
           
        }
    }
    
    // MARK: - NSFetchedResultsControllerDelegate
    
    // Whenever changes are made to Core Data the following three methods are invoked. This first method is used to create
    // three fresh arrays to record the index paths that will be changed.
    func controllerWillChangeContent(controller: NSFetchedResultsController) {
        // We are about to handle some new changes. Start out with empty arrays for each change type
        insertedIndexPaths = [NSIndexPath]()
        deletedIndexPaths = [NSIndexPath]()
        updatedIndexPaths = [NSIndexPath]()
        
        println("in controllerWillChangeContent")
    }
    
    // The second method may be called multiple times, once for each Image object that is added, deleted, or changed.
    // We store the incex paths into the three arrays.
    func controller(controller: NSFetchedResultsController, didChangeObject anObject: AnyObject, atIndexPath indexPath: NSIndexPath?, forChangeType type: NSFetchedResultsChangeType, newIndexPath: NSIndexPath?) {
        
        switch type{
            
        case .Insert:
            println("Insert an item")
            insertedIndexPaths.append(newIndexPath!)
            break
        case .Delete:
            println("Delete an item")
            deletedIndexPaths.append(indexPath!)
            break
        case .Update:
            println("Update an item.")
            updatedIndexPaths.append(indexPath!)
            break
        case .Move:
            println("Move an item. We don't expect to see this in this app.")
            break
        default:
            break
        }
    }
    
    // This method is invoked after all of the changed in the current batch have been collected
    // into the three index path arrays (insert, delete, and upate). We now need to loop through the
    // arrays and perform the changes.
    //
    // The most interesting thing about the method is the collection view's "performBatchUpdates" method.
    // Notice that all of the changes are performed inside a closure that is handed to the collection view.
    func controllerDidChangeContent(controller: NSFetchedResultsController) {
        
        println("in controllerDidChangeContent. changes.count: \(insertedIndexPaths.count + deletedIndexPaths.count)")
        
//        collectionView.performBatchUpdates(<#updates: (() -> Void)?##() -> Void#>, completion: <#((Bool) -> Void)?##(Bool) -> Void#>)
        
        collectionView.performBatchUpdates({() -> Void in
            
            for indexPath in self.insertedIndexPaths {
                self.collectionView.insertItemsAtIndexPaths([indexPath])
            }
            
            for indexPath in self.deletedIndexPaths {
                self.collectionView.deleteItemsAtIndexPaths([indexPath])
            }
            
            for indexPath in self.updatedIndexPaths {
                self.collectionView.reloadItemsAtIndexPaths([indexPath])
            }
            
            }, completion: { done in
                logger.debug("Done")
        })
        
    }
    
    
    
    // MARK: - Actions
    
    
    // MARK: Segue
    
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        if segue.identifier == MediaDetailSegueId {
            let destination = segue.destinationViewController as! MediaViewController
            destination.mediaSelected = mediaSelected
            destination.hidesBottomBarWhenPushed = true
        }
    }
  
    
    // MARK: - Utilities

    
    // Display a text in the centered label. Used for message about the collection
    func displayCenteredLabel(message: String) {
        collectionCenteredLabel.text = message
        self.collectionCenteredLabel.hidden = false
        
//        UIView.animateWithDuration(0.8, animations: { () -> Void in
            self.collectionCenteredLabel.alpha = 1
//        })
    }
    
    func hideCenteredLabel() {
        UIView.animateWithDuration(0.4, animations: { () -> Void in
            self.collectionCenteredLabel.alpha = 0
            }) { (success) -> Void in
                self.collectionCenteredLabel.hidden = true
        }
    }
   
    
    // MARK: - NSFetchedResultsController
    
    lazy var fetchedResultsController: NSFetchedResultsController = {
        
        let fetchRequest = NSFetchRequest(entityName: CDMedia.ModelName)
        
        fetchRequest.predicate = NSPredicate(format: "%K = %@", CDMedia.PropertyKeys.State, CDMediaState.Favorited.rawValue)
        fetchRequest.sortDescriptors = []
        
        let fetchedResultsController = NSFetchedResultsController(fetchRequest: fetchRequest, managedObjectContext: self.sharedContext, sectionNameKeyPath: nil, cacheName: nil)
        fetchedResultsController.delegate = self
        
        return fetchedResultsController
    }()
    
}