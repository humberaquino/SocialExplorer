//
//  PinAnnotation.swift
//  SocialExplorer
//
//  Created by Humberto Aquino on 5/10/15.
//  Copyright (c) 2015 Humberto Aquino. All rights reserved.
//

import Foundation
import MapKit
import CoreData

// A class that represents a pin in the map that i associated with a Core data model

@objc
class PinAnnotation: NSObject, MKAnnotation {
    
    var coordinate: CLLocationCoordinate2D
    var objectID: NSManagedObjectID

    var title: String?
    var subtitle: String?

    // The name of the model that the objectID refers to.
    var model: String
    
    init (objectID: NSManagedObjectID, coordinate: CLLocationCoordinate2D, model: String) {
        self.objectID = objectID
        self.coordinate = coordinate
        self.model = model
    }
    
}