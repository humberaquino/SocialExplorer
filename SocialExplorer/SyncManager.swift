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

// Implementation notes:
// All Core data access are via a private context that has the main context as its parent
// The execution runs on its own queue
class SyncManager: NSObject {
    
    static let SyncError = "SyncError"
    static let SyncComplete = "SyncComplete"
    
    let userSettings = UserSettings.sharedInstance()
    
    private var running = false
    
    // List of errors taht occured during a sync
    private var errorList: SynchronizedArray<NSError>!
    
    // The clients to use
    let instagramClient = InstagramClient()
    let foursquareClient = FoursquareClient()
    
    // Synk manager has its own concurrent que to release the main thread ASAP
    let SyncQueue = dispatch_queue_create(Constants.SyncQueueName, DISPATCH_QUEUE_CONCURRENT)
    
    // The private context for the manager
    var privateContext: NSManagedObjectContext!
    
    // Starts the sync process if is not already running
    // It is safe to call this method at any time
    func sync() {
        // 1. Release the calling queue ASAP
        dispatch_async(SyncQueue) {
            // 2. Check if the manager is running. Mark as running if not to be able to continue
            if !self.startSyncIfPossible() {
                logger.debug("Sync running. Skipping")
                return
            }
            
            // Check if at least one service is available
            if self.userSettings.noServiceAvailable() {
                logger.debug("No service active. Skipping")
                self.markSyncAsDone()
                return
            }
            
            logger.debug("Sync started")
            
            // 3. Setup global sync error list
            self.errorList = SynchronizedArray<NSError>()
            
            // 4. Setup temporal context
            self.setupTemporalContext()
            
            // 5. Actually start the sync
            self.startSyncByUpdatingReferences()
        }
    }

    // The starting point for the synchronization process
    func startSyncByUpdatingReferences() {
        self.privateContext.performBlock {
            // 1. Fetch all references with the "new" state
            var error: NSError?
            let newOrFailedReferences = self.fetchAllNewAndFailedReferences(&error)
            if let error = error {
                // We can't continue if we can't access the new references
                self.addErrorSaveAndComplete(error)
                return
            }
            
            let referenceCount = newOrFailedReferences!.count
            
            // 2. Check if there are new references to process
            if referenceCount == 0 {
                logger.debug("No references to update. Check for new locations")
                // TODO
                self.saveAndComplete()
                return
            }
            
            logger.debug("\(referenceCount) references to update")
            
            // 3. For each new reference, fetch its locations
            let newReferenceLocationGroup = dispatch_group_create()
            for reference in newOrFailedReferences! {
                logger.debug("Updating '\(reference.name)' with state '\(reference.state)'")
                self.requestReferenceLocation(reference, dispatchGroup: newReferenceLocationGroup)
            }
            
            // 4. All new references now have locations
           self.saveAndStartSyncLocations(newReferenceLocationGroup)
        }
    }
    
    func saveAndStartSyncLocations(dispatchGroup: dispatch_group_t) {
        dispatch_group_notify(dispatchGroup, self.SyncQueue) {
            // Save in privateContext
            self.privateContext.performBlock {
                var error: NSError?
                self.privateContext.save(&error)
                if let error = error {
                    // This is serius. The references and their locations were not saved
                    self.addErrorSaveAndComplete(error)
                    return
                }
                
                // Great. The references are now updated and have locations.
                // Save in the main context
                CoreDataStackManager.sharedInstance().saveContext() { hadChanges in
                    // And continue downloading the media for each location.
                    // At the end, mark the reference as ready
                    self.syncNewLocations()
                }
            }
        }
    }
    
    func requestReferenceLocation(reference: CDReference, dispatchGroup: dispatch_group_t) {
        // Get reference for instagram if enabled
        self.requestReferenceLocationForInstagram(reference, dispatchGroup: dispatchGroup)
        // Get references for foursquare if enabled
        self.requestReferenceLocationForFoursquare(reference, dispatchGroup: dispatchGroup)
    }
    
    func requestReferenceLocationForInstagram(reference: CDReference, dispatchGroup: dispatch_group_t) {
        // Get reference for instagram if enabled
        if !userSettings.instagram.isServiceActive() {
            logger.debug("Instagram service disabled. Not looking for instagram locations")
            return
        }
        // 3.1 Get the locations around the reference coordinates
        dispatch_group_enter(dispatchGroup)
        self.instagramClient.requestLocations(reference.coordinate) {
            (instagramLocationDTOList, error) -> Void in
            self.privateContext.performBlock {
                if let error = error {
                    logger.error("\(reference.name)[Instagram] -> FAILED: \(error.localizedDescription)")
                    reference.markAsFailedWithError(error)
                    dispatch_group_leave(dispatchGroup)
                    return
                }
                
                logger.debug("\(reference.name) -> \(instagramLocationDTOList.count) locations")
                
                // Create locations for each instagram location
                for instagramLocation in instagramLocationDTOList {
                    // Check if location already exists
                    var error: NSError?
                    let locations = self.fecthCDLocationWithId(instagramLocation.id!,
                        andType: CDLocationType.Instagram, error: &error)
                    if let error = error {
                        // Add error to inform
                        self.errorList.append(error)
                        break
                    }
                    
                    let dict = instagramLocation.asDict()
                    self.associateOrCreateLocation(reference, locationDict: dict, locations: locations!)
                }
                logger.debug("\(reference) -> \(reference.locationList.count) locations")
                
                // MArk as "with value"
                reference.state = CDReferenceState.WithLocations.rawValue
                dispatch_group_leave(dispatchGroup)
            }
        }
    }
    
    func requestReferenceLocationForFoursquare(reference: CDReference, dispatchGroup: dispatch_group_t) {
        if !userSettings.foursquare.isServiceActive() {
            logger.debug("Gooursquare service disabled. Not looking for foursquare locations")
            return
        }
        
        // 3.1 Get the locations around the reference coordinates
        dispatch_group_enter(dispatchGroup)
        self.foursquareClient.requestVenues(reference.coordinate) {
            (foursquareLocationDTOList, error) -> Void in
            self.privateContext.performBlock {
                if let error = error {
                    logger.error("\(reference.name)[Foursquare] -> FAILED: \(error.localizedDescription)")
                    reference.markAsFailedWithError(error)
                    dispatch_group_leave(dispatchGroup)
                    return
                }
                
                logger.debug("\(reference.name) -> \(foursquareLocationDTOList.count) locations")
                
                // Create locations for each instagram location
                for foursquareLocation in foursquareLocationDTOList {
                    // Check if location already exists
                    var error: NSError?
                    let locations = self.fecthCDLocationWithId(foursquareLocation.id!,
                        andType: CDLocationType.Foursquare ,error: &error)
                    if let error = error {
                        // Add error to inform
                        self.errorList.append(error)
                        break
                    }
                    let dict = foursquareLocation.asDict()
                    self.associateOrCreateLocation(reference, locationDict: dict, locations: locations!)
                }
                logger.debug("\(reference) -> \(reference.locationList.count) locations")
                
                // Mark as "with value"
                reference.state = CDReferenceState.WithLocations.rawValue
                dispatch_group_leave(dispatchGroup)
            }
        }
    }
    
    func associateOrCreateLocation(reference: CDReference, locationDict dict: [String: AnyObject], locations: [CDLocation]) {
        if locations.count == 0 {
            // New location
            let newLocation = CDLocation(dictionary: dict, context: self.privateContext)
            // Associate the reference with the new location
            reference.addLocation(newLocation)
            logger.debug("New: \(newLocation)")
            
        } else {
            // Location exits
            let existingLocation = locations.first!
            reference.addLocation(existingLocation)
            logger.debug("Existing: \(existingLocation)")
        }
    }
    
    func syncNewLocations () {
        self.privateContext.performBlock {
            // 1. Get all new locations
            // TODO: Should I get the failed too?
            var error: NSError?
            let newLocations = self.fetchAllNewAndFailedLocations(&error)
            if let error = error {
                // We can't continue if we can't access the new references
                self.addErrorSaveAndComplete(error)
                return
            }
            
            let newLocationCount = newLocations!.count
            
            // 2. Check if there are no new locations
            if newLocationCount == 0 {
                logger.debug("No new locations. Completing")
                self.saveAndComplete()
                return
            }
            
            logger.debug("New locations: \(newLocationCount)")
            
            // 3. For each location let's get its medias
            
            // 3.a Start a dispatch group to know when all locations were requested
            let mediaDownloadGroup = dispatch_group_create()
            // For each new location get its media
            for newLocation in newLocations! {
                logger.debug("Entering location \(newLocation.locationType): \(newLocation)")
                
                // Handle the location depending on the type
                
                if newLocation.locationType == CDLocationType.Instagram.rawValue {
                    // Instagram
                    self.handleInstagramMediaForLocation(newLocation, dispatchGroup: mediaDownloadGroup)
                } else {
                    // Foursquare
                    self.handleFoursquareMediaForVenue(newLocation, dispatchGroup: mediaDownloadGroup)
                }
                
            }
            
           
            dispatch_group_notify(mediaDownloadGroup, self.SyncQueue) {
                 // 4. All locations now have their medias
                logger.debug("Media download complete")
                // TODO: Update reference state
                self.privateContext.performBlock {
                    self.updateReferenceStateBasedOnMedia()
                    
                    self.saveAndComplete()
                }
            }
        }
    }
    
    
    
    func handleFoursquareMediaForVenue(location: CDLocation, dispatchGroup: dispatch_group_t) {
        if !userSettings.foursquare.isServiceActive() {
            logger.debug("Foursquare service disabled. Not looking for medias")
            return
        }
        
        // 3.b For this single location request its medias
        dispatch_group_enter(dispatchGroup)
        self.foursquareClient.requestVenueInfoBy(location.id) {
            (foursquarePhotoDTOList, error) -> Void in
            if let error = error {
                logger.error("Error while asking foursquare photo: \(error.localizedDescription)")
                self.errorList.append(error)
                dispatch_group_leave(dispatchGroup)
                return
            }
            
            // 3.c
            self.privateContext.performBlock {
                // For each media create a entity and save it
                for foursquarePhotoDTO in foursquarePhotoDTOList {
                    // Create CDMedia
                    let media = CDMedia(dto: foursquarePhotoDTO, context: self.privateContext)
                    // Associate it with the location
                    media.parentLocation = location
                }
                
                location.state = CDLocationState.Ready.rawValue
                
                logger.debug("Leaving location: \(location)")
                // 3.d Mark as completed
                dispatch_group_leave(dispatchGroup)
            }
        }
    }
    
    
    func handleInstagramMediaForLocation(location: CDLocation, dispatchGroup: dispatch_group_t) {
        if !userSettings.instagram.isServiceActive() {
            logger.debug("Instagram service disabled. Not looking for medias")
            return
        }
        
        // 3.b For this single location request its medias
        dispatch_group_enter(dispatchGroup)
        self.instagramClient.requestMediaRecentForLocationId(location.id) {
            (instagramMediaDTOList, error) -> Void in
            if let error = error {
                logger.error("Error while asking instagram media: \(error.localizedDescription)")
                self.errorList.append(error)
                dispatch_group_leave(dispatchGroup)
                return
            }
            
            // 3.c
            self.privateContext.performBlock {
                // For each media create a entity and save it
                for instagramMedia in instagramMediaDTOList {
                    // Create CDMedia
                    let media = CDMedia(dto: instagramMedia, context: self.privateContext)
                    // Associate it with the location
                    media.parentLocation = location
                }
                
                location.state = CDLocationState.Ready.rawValue
                
                logger.debug("Leaving location: \(location)")
                // 3.d Mark as completed
                dispatch_group_leave(dispatchGroup)
            }
        }
    }
    
    func updateReferenceStateBasedOnMedia() {
        var error: NSError?
        let references = self.fetchAllWithLocationsReferences(&error)
        if let error = error {
            logger.error("Error while fetching references with locations: \(error.localizedDescription)")
            errorList.append(error)
            return
        }
        if references!.count == 0 {
            logger.debug("No references with locations. Skipping")
            return
        }
        for reference in references! {
            let ready = reference.markAsReadyIfPossible()
            logger.debug("Reference '\(reference.name)' ready = \(ready)")
        }
    }
    
    func addErrorSaveAndComplete(error: NSError) {
        logger.error("Sync error: \(error)")
        errorList.append(error)
        saveAndComplete()
    }
    
    func saveAndComplete() {
        self.privateContext.performBlock {
            // All media downloaded
            var error: NSError?
            self.privateContext.save(&error)
            if let error = error {
                self.errorList.append(error)
            }
            
            CoreDataStackManager.sharedInstance().saveContext() { hadChanges in
                logger.info("Sync done")
                if self.errorList.count > 0 {
                     NSNotificationCenter.defaultCenter().postNotificationName(SyncManager.SyncError, object: self.errorList)
                } else {
                   
                    NSNotificationCenter.defaultCenter().postNotificationName(SyncManager.SyncComplete, object: nil)
                }
                 self.markSyncAsDone()
            }
        }
    }
    
    // Initializes a new temporal private context
    // It's parent context is the main context
    // The context is valid as per-sync basis
    func setupTemporalContext() {
        self.privateContext = NSManagedObjectContext(concurrencyType: .PrivateQueueConcurrencyType)
        self.privateContext.parentContext = CoreDataStackManager.sharedInstance().managedObjectContext!
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
    
    func fetchAllNewAndFailedLocations(inout error: NSError?) -> [CDLocation]? {
        var request = NSFetchRequest(entityName: CDLocation.ModelName)
        
        let newLocations = NSPredicate(format: "%K = %@", CDLocation.Keys.state, CDLocationState.New.rawValue)
        let failedLocations = NSPredicate(format: "%K = %@", CDLocation.Keys.state, CDLocationState.Failed.rawValue)
        
        request.predicate = NSCompoundPredicate(type: .OrPredicateType, subpredicates: [newLocations, failedLocations])
        
        return self.privateContext.executeFetchRequest(request, error: &error) as? [CDLocation]
    }
    
    func fecthCDLocationWithId(id: String, andType type: CDLocationType, inout error: NSError?) -> [CDLocation]? {
        var request = NSFetchRequest(entityName: CDLocation.ModelName)
        
        let locationIdPredicate = NSPredicate(format: "%K = %@", CDLocation.Keys.Id, id)
        let locationTypePredicate = NSPredicate(format: "%K = %@", CDLocation.Keys.LocationType, type.rawValue)
        
        request.predicate = NSCompoundPredicate(type: .AndPredicateType, subpredicates: [locationIdPredicate, locationTypePredicate])
        
        return self.privateContext.executeFetchRequest(request, error: &error) as? [CDLocation]
    }
    
    func fetchAllNewAndFailedReferences(inout error: NSError?) -> [CDReference]? {
        var request = NSFetchRequest(entityName: CDReference.ModelName)
        
        let newReferences = NSPredicate(format: "%K = %@", CDReference.Keys.state, CDReferenceState.New.rawValue)
        let failedReferences = NSPredicate(format: "%K = %@", CDReference.Keys.state, CDReferenceState.Failed.rawValue)
        
        request.predicate = NSCompoundPredicate(type: .OrPredicateType, subpredicates: [newReferences, failedReferences])
        
        return self.privateContext.executeFetchRequest(request, error: &error) as? [CDReference]
    }
    
    func fetchAllWithMediaReferences(inout error: NSError?) -> [CDReference]? {
        var request = NSFetchRequest(entityName: CDReference.ModelName)
        request.predicate = NSPredicate(format: "%K != %@", CDReference.Keys.state, CDReferenceState.WithLocations.rawValue)
        return self.privateContext.executeFetchRequest(request, error: &error) as? [CDReference]
    }
    
    func fetchAllWithLocationsReferences(inout error: NSError?) -> [CDReference]? {
        var request = NSFetchRequest(entityName: CDReference.ModelName)
        
        request.predicate = NSPredicate(format: "%K = %@", CDReference.Keys.state, CDReferenceState.WithLocations.rawValue)
        
        return self.privateContext.executeFetchRequest(request, error: &error) as? [CDReference]
        
    }
    
    class func sharedInstance() -> SyncManager {
        struct Static {
            static let instance = SyncManager()
        }
        return Static.instance
    }
}



