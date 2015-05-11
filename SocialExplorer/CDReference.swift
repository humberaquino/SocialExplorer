//
//  InterestingArea.swift
//  SocialExplorer
//
//  Created by Humberto Aquino on 5/5/15.
//  Copyright (c) 2015 Humberto Aquino. All rights reserved.
//

import Foundation
import CoreData
import CoreLocation
import MapKit
import SwiftyJSON

enum CDReferenceState: String {
    case New = "new"
    case WithLocations = "with_locations"
//    case Ready = "ready"
}


// Represents a reference poin in the map. It has a list of locations associated with it

@objc(CDReference)

class CDReference: NSManagedObject, Coordenable {
    
    static let ModelName = "Reference"
    
    struct Default {
        static let LatitudeDelta = 0.05
        static let LongitudeDelta = 0.05
    }
    
    struct Keys {
        static let Longitude = "longitude"
        static let Latitude = "latitude"
        static let state = "state"
    }
    
    @NSManaged var latitude: Double
    @NSManaged var longitude: Double
    
    @NSManaged var latitudeDelta: Double
    @NSManaged var longitudeDelta: Double
    
    @NSManaged var state: String
    @NSManaged var name: String?
    
    @NSManaged var locationList: NSOrderedSet
    
    override init(entity: NSEntityDescription, insertIntoManagedObjectContext context: NSManagedObjectContext?) {
        super.init(entity: entity, insertIntoManagedObjectContext: context)
    }
    
    init(dictionary: [String: AnyObject], context: NSManagedObjectContext) {
        let entity = NSEntityDescription.entityForName(CDReference.ModelName, inManagedObjectContext: context)!
        super.init(entity: entity, insertIntoManagedObjectContext: context)
        
        latitude = dictionary[Keys.Latitude] as! Double
        longitude = dictionary[Keys.Longitude] as! Double
        
        latitudeDelta = Default.LatitudeDelta
        longitudeDelta = Default.LongitudeDelta
        
        state = CDReferenceState.New.rawValue
    }
    
    
    override var description: String {
        let locationDescription = "\(latitude), \(longitude)"
        if let name = name {
            return "Reference '\(name)': \(locationDescription)"
        } else {
            return "Reference: \(locationDescription)"
        }        
    }
    
    func addLocation(location: CDLocation) {
        locationList = locationList.cloneAndAddObject(location)
    }
    
    
    func countNonEmptyLocations() -> Int {
        var total = 0

        locationList.enumerateObjectsUsingBlock { (obj, index, done) -> Void in
            let location = obj as! CDLocation
            if location.mediaList.count > 0 {
                total++
            }
        }
        
        return total
    }
    
    // MARK - MKAnnotation
    
    var span: MKCoordinateSpan {
        get {
            return MKCoordinateSpan(latitudeDelta: latitudeDelta, longitudeDelta: longitudeDelta)
        }
        set {
            self.latitudeDelta = newValue.latitudeDelta
            self.longitudeDelta = newValue.longitudeDelta
        }
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
    
        
    // MARK: Utility
    
    func markAsNew() {
        state = CDReferenceState.New.rawValue
    }
    
//    func isReady() -> Bool {
//        if state == CDReferenceState.Ready.rawValue {
//            return true
//        }
//        return false
//    }
    
//    func isUpdating() -> Bool {
//        if state == CDReferenceState.Updating.rawValue {
//            return true
//        }
//        return false
//    }
//    
//    func markAsUpdating() {
//        state = CDReferenceState.Updating.rawValue
//    }
    
//    func markAsReady() {
//        state = CDReferenceState.Ready.rawValue
//    }
}