//
//  InstagramLocaiton.swift
//  SocialExplorer
//
//  Created by Humberto Aquino on 5/8/15.
//  Copyright (c) 2015 Humberto Aquino. All rights reserved.
//

import Foundation
import CoreData
import SwiftyJSON
import MapKit

enum CDLocationState: String {
    case New = "new" // It doesn't have media associated
    case Ready = "ready" // Is ready. Has media associated
    case Saved = "saved" // Is ready and is saved. This means that the user
}

@objc(CDLocation)

class CDLocation: NSManagedObject, MKAnnotation, Coordenable {
    
    static let ModelName = "Location"
    
    struct Keys {
        static let Longitude = "longitude"
        static let Latitude = "latitude"
        static let Id = "id"
        static let Name = "name"
        static let State = "state"
        static let ReferenceList = "referenceList"
    }
    
    @NSManaged var id: String
    @NSManaged var name: String
    @NSManaged var latitude: Double
    @NSManaged var longitude: Double
    @NSManaged var state: String
    
    // The list of references that use this location
    @NSManaged var referenceList: NSOrderedSet
    
    // The list of media that this location has
    @NSManaged var mediaList: NSOrderedSet
    
    override init(entity: NSEntityDescription, insertIntoManagedObjectContext context: NSManagedObjectContext?) {
        super.init(entity: entity, insertIntoManagedObjectContext: context)
    }
    
    init(dictionary: [String: AnyObject], context: NSManagedObjectContext) {
        let entity = NSEntityDescription.entityForName(CDLocation.ModelName, inManagedObjectContext: context)!
        super.init(entity: entity, insertIntoManagedObjectContext: context)
        
        id = dictionary[Keys.Id] as! String
        name = dictionary[Keys.Name] as! String
        latitude = dictionary[Keys.Latitude] as! Double
        longitude = dictionary[Keys.Longitude] as! Double
        
        state = CDLocationState.New.rawValue
    }
    
    init(json: JSON, context: NSManagedObjectContext) {
        let entity = NSEntityDescription.entityForName(CDLocation.ModelName, inManagedObjectContext: context)!
        super.init(entity: entity, insertIntoManagedObjectContext: context)
        
        id = json[Keys.Id].stringValue
        name = json[Keys.Name].stringValue
        latitude = json[Keys.Latitude].doubleValue
        longitude = json[Keys.Longitude].doubleValue
        
        state = CDLocationState.New.rawValue
    }
    
    func addReference(reference: CDReference) {
        referenceList = referenceList.cloneAndAddObject(reference)
    }
    
    func addMedia(media: CDMedia) {
        mediaList = mediaList.cloneAndAddObject(media)
    }
    
    override var description: String {
        return "[\(id)]: \(name)"
    }
    
    var coordinate: CLLocationCoordinate2D {
        get {
            return CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
        }
        set {
            self.latitude = newValue.latitude
            self.longitude = newValue.longitude
        }
    }
    
    var title: String {
        return name
    }
    
    var subtitle: String? = nil
    
    
}