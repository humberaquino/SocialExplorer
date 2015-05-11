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

@objc
class PinAnnotation: NSObject, MKAnnotation {
    
    var coordinate: CLLocationCoordinate2D
    var objectID: NSManagedObjectID
    var title: String?
    var subtitle: String?
    
    var model: String
    
    init (objectID: NSManagedObjectID, coordinate: CLLocationCoordinate2D, model: String) {
        self.objectID = objectID
        self.coordinate = coordinate
        self.model = model
    }
    
}