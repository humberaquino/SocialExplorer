//
//  CoreDataStackManager.swift
//  SocialExplorer
//
//  Created by Humberto Aquino on 5/5/15.
//  Copyright (c) 2015 Humberto Aquino. All rights reserved.
//

import Foundation
import CoreData
import XCGLogger

// The core data stack manager
// The scheme used has two context:
//  1. saveManagedObjectContext: The context that interacts with the persistent store coordinator. Is a PrivateQueueConcurrencyType and for that reason it does not use the main queue.
//  2. managedObjectContext: The main context that runs on the main queue. Is the one used to create new private contexts or interac from the UI
class CoreDataStackManager {    
    
    // MARK: - Core Data Saving support
    
    // Main save method. It saves the main context to the SaveContext whicn does the "write" to the
    // PSC in the background
    func saveContext (wait: Bool = false, completion: ((hadChanges: Bool) -> Void)? = nil) {
        if let mainContext = self.managedObjectContext,
            let saveContext = self.saveManagedObjectContext {
                
                let completionCalledIfExist: (changed: Bool) -> Void = { (changed) in
                    if let completion = completion {
                        dispatch_async(dispatch_get_main_queue()) {
                            completion(hadChanges: changed)
                        }
                    }
                }
                
                // 1. Save the main context
                if mainContext.hasChanges {
                    mainContext.performBlockAndWait {
                        var error: NSError?
                        mainContext.save(&error)
                        if error != nil {
                            logger.severe("Unresolved error \(error), \(error!.userInfo)")
                            abort()
                        }
                    }
                    
                    let savePrivate: () -> Void = {
                        var error: NSError?
                        saveContext.save(&error)
                        if error != nil {
                            logger.severe("Unresolved error \(error), \(error!.userInfo)")
                            abort()
                        }
                        completionCalledIfExist(changed: true)
                    }
                    
                    if saveContext.hasChanges {
                        if wait {
                            saveContext.performBlockAndWait(savePrivate)
                        } else {
                            saveContext.performBlock(savePrivate)
                        }
                    } else {
                        completionCalledIfExist(changed: false)
                    }
                } else {
                    // No changes in main queue
                    completionCalledIfExist(changed: false)
                }
        }
    }
    
    
    // MARK: - Core Data stack
    
    // The context used to save the data into the PSC
    private lazy var saveManagedObjectContext: NSManagedObjectContext? = {
        
        logger.info("Initializing the managed object context property")
        
        // Returns the managed object context for the application (which is already bound to the persistent store coordinator for the application.) This property is optional since there are legitimate error conditions that could cause the creation of the context to fail.
        let coordinator = self.persistentStoreCoordinator
        if coordinator == nil {
            return nil
        }
        var saveManagedObjectContext = NSManagedObjectContext(concurrencyType:.PrivateQueueConcurrencyType)
        saveManagedObjectContext.persistentStoreCoordinator = coordinator
        return saveManagedObjectContext
    }()
    
    // Main context that runs on the main queue. It's parent is the saveManagedObjectContext
    lazy var managedObjectContext: NSManagedObjectContext? = {
        
        var managedObjectContext = NSManagedObjectContext(concurrencyType: NSManagedObjectContextConcurrencyType.MainQueueConcurrencyType
        )
        managedObjectContext.parentContext = self.saveManagedObjectContext
        
        return managedObjectContext
    }()
    
    lazy var persistentStoreCoordinator: NSPersistentStoreCoordinator? = {
        // The persistent store coordinator for the application. This implementation creates and return a coordinator, having added the store for the application to it. This property is optional since there are legitimate error conditions that could cause the creation of the store to fail.
        // Create the coordinator and store
        logger.info("Initializing the persistent store coodinator")
        
        var coordinator: NSPersistentStoreCoordinator? = NSPersistentStoreCoordinator(managedObjectModel: self.managedObjectModel)
        let url = self.applicationDocumentDirectory.URLByAppendingPathComponent(Constants.SQLiteFilename)
        
        var error: NSError? = nil
        if coordinator!.addPersistentStoreWithType(NSSQLiteStoreType, configuration: nil, URL: url, options: nil, error: &error) == nil {
            coordinator = nil
            // Report any error we got.
            let userInfo: [NSObject : AnyObject] = [
                NSLocalizedDescriptionKey: "Failed to initialize the application's saved data",
                NSLocalizedFailureReasonErrorKey: "There was an error creating or loading the application's saved data.",
                NSUnderlyingErrorKey: error!
            ]
            
            error = NSError(domain: Error.Domain, code: Error.PersistentStoreCoordiantorInitialization, userInfo: userInfo)
            
            logger.severe("Unresolved error \(error), \(error!.userInfo)")
            abort()
        }
        
        return coordinator
    }()
    
    lazy var managedObjectModel: NSManagedObjectModel = {
        // The managed object model for the application. This property is not optional.
        // It is a fatal error for the application not to be able to find and load its model.
        logger.info("Initializing the managed object model")
        
        let modelURL = NSBundle.mainBundle().URLForResource(Constants.ModelName, withExtension: Constants.ModelExtension)!
        return NSManagedObjectModel(contentsOfURL: modelURL)!
    }()
    
    lazy var imagesDocumentDirectory: NSURL = {
        let imagesDirectory = self.applicationDocumentDirectory.URLByAppendingPathComponent(Constants.ImagesDirectory)
        let imageDirectoryPath = imagesDirectory.path!
        
        var isDirectory: ObjCBool = ObjCBool(false)
        if NSFileManager.defaultManager().fileExistsAtPath(imageDirectoryPath, isDirectory: &isDirectory) {
            // File exits
            if !isDirectory {
                logger.severe("The intended images directory is actually a file: \(imagesDirectory)")
                abort()
            }
            // Success. Directory exists.
        } else {
            // File does not exist. Create a directory
            var error: NSError? = nil
            if NSFileManager.defaultManager().createDirectoryAtPath(imageDirectoryPath, withIntermediateDirectories: false, attributes: nil, error: &error) {
                // success
                logger.info("Images directory created: \(imagesDirectory)")
            } else {
                logger.severe("Error while trying to create the intended images directory: \(imagesDirectory)")
                if let error = error {
                    logger.severe("Error: \(error.localizedDescription)")
                    abort()
                }
            }
        }
        
        
        return imagesDirectory
    }()
    
    lazy var applicationDocumentDirectory: NSURL = {
        logger.info("Initializing the application document directory")
        
        let urls = NSFileManager.defaultManager().URLsForDirectory(.DocumentDirectory, inDomains: .UserDomainMask)
        return urls.first as! NSURL
    }()
    
    // MARK: utils
    
    func pathForfilename(filename: String) -> String? {
        let imagesDirecotory = CoreDataStackManager.sharedInstance().imagesDocumentDirectory
        let imagePathURL = imagesDirecotory.URLByAppendingPathComponent(filename)
        return imagePathURL.path
    }
    
    // MARK: Shared instance
    
    class func sharedInstance() -> CoreDataStackManager {
        struct Static {
            static let instance = CoreDataStackManager()
        }
        
        return Static.instance
    }

}
