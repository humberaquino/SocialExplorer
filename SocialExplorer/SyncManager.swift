//
//  SyncManager.swift
//  SocialExplorer
//
//  Created by Humberto Aquino on 5/9/15.
//  Copyright (c) 2015 Humberto Aquino. All rights reserved.
//

import Foundation
import XCGLogger
import CoreData

// Handles syncronizartion request and notifications
// This should be the starting point of syncronization
class SyncManager: NSObject {
    
    let SyncError = "SyncError"
    
    private var running = false
    private var errorList = SynchronizedArray<NSError>()
    
    let instagramClient = InstagramClient()
    
    // Synk manager has its own concurrent que to release the main thread ASAP
    let SyncQueue = dispatch_queue_create(Constants.SyncQueueName, DISPATCH_QUEUE_CONCURRENT)
    
    var privateContext: NSManagedObjectContext!
    
    // Starts a sync if is not running
    // It is safe to call this method at any time
    func sync() {
        dispatch_async(SyncQueue) {
            // Check if the manager is running
           
            if !self.startSyncIfPossible() {
                logger.debug("Sync running. Skipping")
                return
            }
            
            logger.debug("Sync started")
            // Setup provate context
            self.privateContext = NSManagedObjectContext(concurrencyType: .PrivateQueueConcurrencyType)
            self.privateContext.parentContext = CoreDataStackManager.sharedInstance().managedObjectContext!
            
            // Start sync
            self.privateContext.performBlock {
                
                // 1. Fetch all "new" references
                var error: NSError?
                let newReferences = self.fetchAllNewReferences(&error)
                if let error = error {
                    // Fetch error
                    self.notifyError(error)
                    return
                }
                
                logger.debug("\(newReferences!.count) new references")                
                
                // 2. For each new reference, fetch its locations
                let newReferenceLocationGroup = dispatch_group_create()
                for reference in newReferences! {
                    
                    
                    dispatch_group_enter(newReferenceLocationGroup)
                    self.instagramClient.requestLocations(reference.coordinate) {
                        (instagramLocationDTOList, error) -> Void in

                        if let error = error {
                            self.errorList.append(error)
                            dispatch_group_leave(newReferenceLocationGroup)
                            return
                        }
                        
                        logger.debug("\(reference.name!) -> \(instagramLocationDTOList.count) locations")
                        
                        // Create locations for each instagram location
                        
                        self.privateContext.performBlock {
                            
                            for instagramLocation in instagramLocationDTOList {
                                // Check if location already exists
                                var error: NSError?
                                let locations = self.fecthCDLocationWithId(instagramLocation.id!, error: &error)
                                if let error = error {
                                    self.notifyError(error)
                                    return
                                }
                                
                                if locations!.count == 0 {
                                    // New location
                                    let dict: [String: AnyObject] = [
                                        CDLocation.Keys.Id: instagramLocation.id!,
                                        CDLocation.Keys.Latitude: instagramLocation.latitude!,
                                        CDLocation.Keys.Longitude: instagramLocation.longitude!,
                                        CDLocation.Keys.Name: instagramLocation.name!
                                    ]
                                    
                                    let newLocation = CDLocation(dictionary: dict, context: self.privateContext)
                                    // Associate the reference with the new location
                                    reference.addLocation(newLocation)
                                    logger.debug("New: \(newLocation)")
                                    
                                } else {
                                    // Location exits
                                    let existingLocation = locations!.first!
                                    reference.addLocation(existingLocation)
                                    logger.debug("Existing: \(existingLocation)")
                                }
                            }
                            logger.debug("\(reference) -> \(reference.locationList.count) locations")
                            // All locations are now associated to the reference
                            reference.state = CDReferenceState.WithLocations.rawValue
                            dispatch_group_leave(newReferenceLocationGroup)
                        }
                    }
                }
                
                dispatch_group_notify(newReferenceLocationGroup, self.SyncQueue) {
                    // Check if there were errors in the group
                    if self.errorList.count > 0 {
                        // FIXME: Use all errors
                        self.notifyError(self.errorList[0])
                        return
                    }
                    
                    // Save in privateContext
                    var error: NSError?
                    self.privateContext.save(&error)
                    if let error = error {
                        self.notifyError(error)
                        return
                    }
                    
                    CoreDataStackManager.sharedInstance().saveContext() { hadChanges in
                        // CDReference now have locations
                        // Continue downloading the media for each location. At the end, mark the reference as ready
                        
                        self.privateContext.performBlock {
                            var error: NSError?
                            let newLocations = self.fetchAllNewLocations(&error)
                            if let error = error {
                                self.notifyError(error)
                                return
                            }
                            
                            logger.debug("New locations: \(newLocations!.count)")
                            
                            // If there are now new locations then complete
                            if newLocations!.count == 0 {
                                 self.saveAndComplete()
                                return
                            }
                            
                            // There is at least one new location
                            let mediaDownloadGroup = dispatch_group_create()
                            // For each new location get its media
                            for newLocation in newLocations! {
                                dispatch_group_enter(mediaDownloadGroup)
                                self.instagramClient.requestMediaRecentForLocationId(newLocation.id) {
                                    (instagramMediaDTOList, error) -> Void in
                                    if let error = error {
                                        // TODO: Do something with the error
                                        dispatch_group_leave(mediaDownloadGroup)
                                        return
                                    }
                                    
                                    self.privateContext.performBlock {
                                        // For each media create a entity and save it
                                        for instagramMedia in instagramMediaDTOList {
                                            // Create CDMedia
                                            let media = CDMedia(dto: instagramMedia, context: self.privateContext)
                                            // Associate it with the location
                                            media.parentLocation = newLocation
                                        }

                                        newLocation.state = CDLocationState.Ready.rawValue
                                        
                                        dispatch_group_leave(mediaDownloadGroup)
                                    }
                                }
                            }
                            
                            dispatch_group_notify(mediaDownloadGroup, self.SyncQueue) {
                                self.saveAndComplete()
                            }
                        }
                    }
                }
            }
        }
    }

    func saveAndComplete() {
        if self.errorList.count > 0 {
            // FIXME: Use all errors
            self.notifyError(self.errorList[0])
            return
        }
        self.privateContext.performBlock {
            // All media downloaded
            var error: NSError?
            self.privateContext.save(&error)
            if let error = error {
                self.notifyError(error)
                return
            }
            CoreDataStackManager.sharedInstance().saveContext() { hadChanges in
                
                logger.info("Sync done")
                self.markSyncAsDone()
            }
        }
    }
    
    // MARK: Private context methods
    
    func notifyError(error: NSError) {
        logger.error("Sync error: \(error)")
        markSyncAsDone()
        NSNotificationCenter.defaultCenter().postNotificationName(self.SyncError, object: error)
    }
    
    // MARK: Utils
    func startSyncIfPossible() -> Bool {
        var started = false
        
        objc_sync_enter(self)
        if !self.running {
            // Mark as running
            self.running = true
            started = true
        }
        objc_sync_exit(self)
        return started
    }
    
    private func markSyncAsDone() {
        objc_sync_enter(self)
        self.running = false
        objc_sync_exit(self)
    }
    
    
    // MARK: Fetching
    
    func fetchAllNewLocations(inout error: NSError?) -> [CDLocation]? {
        var request = NSFetchRequest(entityName: CDLocation.ModelName)
        request.predicate = NSPredicate(format: "%K = %@", CDLocation.Keys.State, CDLocationState.New.rawValue)
        return self.privateContext.executeFetchRequest(request, error: &error) as? [CDLocation]
    }
    
    func fecthCDLocationWithId(id: String, inout error: NSError?) -> [CDLocation]? {
        var request = NSFetchRequest(entityName: CDLocation.ModelName)
        request.predicate = NSPredicate(format: "%K = %@", CDLocation.Keys.Id, id)
        return self.privateContext.executeFetchRequest(request, error: &error) as? [CDLocation]
    }
    
    func fetchAllNewReferences(inout error: NSError?) -> [CDReference]? {
        var request = NSFetchRequest(entityName: CDReference.ModelName)
        request.predicate = NSPredicate(format: "%K = %@", CDReference.Keys.state, CDReferenceState.New.rawValue)
        return self.privateContext.executeFetchRequest(request, error: &error) as? [CDReference]
    }
    
    func fetchAllWithMediaReferences(inout error: NSError?) -> [CDReference]? {
        var request = NSFetchRequest(entityName: CDReference.ModelName)
        request.predicate = NSPredicate(format: "%K != %@", CDReference.Keys.state, CDReferenceState.WithLocations.rawValue)
        return self.privateContext.executeFetchRequest(request, error: &error) as? [CDReference]
    }
    
    class func sharedInstance() -> SyncManager {
        struct Static {
            static let instance = SyncManager()
        }
        return Static.instance
    }
}



