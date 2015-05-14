//
//  Config.swift
//  SocialExplorer
//
//  Created by Humberto Aquino on 5/3/15.
//  Copyright (c) 2015 Humberto Aquino. All rights reserved.
//

import Foundation
import MapKit

extension CoreDataStackManager {
    struct Constants {
        static let SQLiteFilename = "SocialExplorer.sqlite"
        static let ModelName = "SocialExplorerModel"
        static let ModelExtension = "momd"
        static let ImagesDirectory = "images"
    }
    struct Error {
        static let Domain = "CoreData"
        // Error while trying to initialize the PersistentStoreCoordiantor
        // Hint: Check the Core data stack
        static let PersistentStoreCoordiantorInitialization = 5000
    }
}

// MARK: - Constants

extension DiscoverMapViewController {
    struct UI {
        static let MinimumPressDuration:NSTimeInterval = 2
    }
}

extension SyncManager {
    struct Constants {
        static let SyncQueueName = "me.humberaquino.SyncMaster"
    }
}

// Ref: http://stackoverflow.com/a/7200744/223228
extension MKMapView {
    
    func zoomToFitCurrentCoordenables(animated: Bool) {
        let locations = self.annotations as NSArray
        zoomToFitCoordenables(locations, animated: animated)
    }
    
    func zoomToFitCoordenables(coordenables: NSArray, animated: Bool) {
        if coordenables.count == 0 {
            return
        }
        
        var topLeftCoord = CLLocationCoordinate2D(latitude: -90, longitude: 180)
        var bottomRightCoord = CLLocationCoordinate2D(latitude: 90, longitude: -180)
        
        //        let locations = self.annotations as NSArray
        
        for element in coordenables {
            let location = element as! Coordenable
            topLeftCoord.longitude = fmin(topLeftCoord.longitude, location.coordinate.longitude)
            topLeftCoord.latitude = fmax(topLeftCoord.latitude, location.coordinate.latitude)
            bottomRightCoord.longitude = fmax(bottomRightCoord.longitude, location.coordinate.longitude)
            bottomRightCoord.latitude = fmin(bottomRightCoord.latitude, location.coordinate.latitude)
        }
        
        let latitude = topLeftCoord.latitude - (topLeftCoord.latitude - bottomRightCoord.latitude) * 0.5
        let longitude = topLeftCoord.longitude + (bottomRightCoord.longitude - topLeftCoord.longitude) * 0.5
        
        let center = CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
        
        // Add extra padding
        let longitudeDelta = fabs(bottomRightCoord.longitude - topLeftCoord.longitude) * 1.1
        let latitudeDelta = fabs(topLeftCoord.latitude - bottomRightCoord.latitude) * 1.6
        let span = MKCoordinateSpan(latitudeDelta: latitudeDelta, longitudeDelta: longitudeDelta)
        
        var region = MKCoordinateRegion(center: center, span: span)
        
        region = self.regionThatFits(region)
        
        self.setRegion(region, animated:animated)
    }
}






