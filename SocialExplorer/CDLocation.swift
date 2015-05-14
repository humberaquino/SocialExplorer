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
    case Failed = "failed"
}

enum CDLocationType: String {
    case Instagram = "instagram"
    case Foursquare = "foursquare"
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
        static let state = "state"
        static let LocationType = "locationType"
    }
    
    @NSManaged var id: String
    @NSManaged var name: String
    @NSManaged var latitude: Double
    @NSManaged var longitude: Double
    @NSManaged var state: String
    
    @NSManaged var locationType: String
    
    // The list of references that use this location
    @NSManaged var referenceList: NSOrderedSet
    
    // The list of media that this location has
    @NSManaged var mediaList: NSOrderedSet
    
    
    @NSManaged var failureDescription: String?
    
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
        
        locationType = dictionary[Keys.LocationType] as! String
        
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
    
    var subtitle: String {
        return "\(mediaList.count) medias"
    }
    
    func markAsFailedWithError(error: NSError) {
        state = CDLocationState.Failed.rawValue
        failureDescription = error.localizedDescription
    }
    
}