//
//  UserSettings.swift
//  SocialExplorer
//
//  Created by Humberto Aquino on 5/4/15.
//  Copyright (c) 2015 Humberto Aquino. All rights reserved.
//

import Foundation
import MapKit

// Singleton used persist and obtain user settings
class UserSettings {
    
    let discoveryMap = DiscoveryMapSettings()
    let instagram = InstagramSettings()
    
    // Singleton declaration
    static func sharedInstance() -> UserSettings {
        struct Static {
            static let instance = UserSettings()
        }
        return Static.instance
    }
    
}


// MARK: - Discovery Map

class DiscoveryMapSettings {
    let LatitudeKey = "map.range.latitude"
    let LongitudeKey = "map.range.longitude"
    let LatitudeDeltaKey = "map.range.latitudeDelta"
    let LongitudeDeltaKey = "map.range.longitudeDelta"
    let MapRangeExistsKey = "map.range.exists"
    
    func loadMapRegion() -> MKCoordinateRegion? {
        let userDefaults = NSUserDefaults.standardUserDefaults()
        let mapRangeExists = userDefaults.boolForKey(MapRangeExistsKey)
        
        if mapRangeExists {
            let latitude = userDefaults.doubleForKey(LatitudeKey)
            let longitude = userDefaults.doubleForKey(LongitudeKey)
            let latitudeDelta = userDefaults.doubleForKey(LatitudeDeltaKey)
            let longitudeDelta = userDefaults.doubleForKey(LongitudeDeltaKey)
            
            let center = CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
            let span = MKCoordinateSpan(latitudeDelta: latitudeDelta, longitudeDelta: longitudeDelta)
            let region = MKCoordinateRegion(center: center, span: span)
            
            return region
        } else {
            // No saved map region
            return nil
        }
    }
    
    func saveMapRegion(region: MKCoordinateRegion) {
        let userDetaults = NSUserDefaults.standardUserDefaults()
        
        userDetaults.setDouble(region.center.latitude, forKey: LatitudeKey)
        userDetaults.setDouble(region.center.longitude, forKey: LongitudeKey)
        userDetaults.setDouble(region.span.latitudeDelta, forKey: LatitudeDeltaKey)
        userDetaults.setDouble(region.span.longitudeDelta, forKey: LongitudeDeltaKey)
        userDetaults.setBool(true, forKey: MapRangeExistsKey)
        
    }
    
}

// MARK: - Instagram

class InstagramSettings {
    
    let ActiveKey = "instagram.active"
    let TokenKey = "instagram.token"
    
    func settings() -> (active: Bool, token: String)? {
        let active = NSUserDefaults.standardUserDefaults().valueForKey(ActiveKey) as? Bool
        let token = currentToken()
        if active != nil && token != nil {
            return (active: active!, token: token!)
        }
        return nil
    }
    
    func saveTokenAsCurrent(token: String) {
        NSUserDefaults.standardUserDefaults().setObject(token, forKey: TokenKey)
        activateService()
    }
    
    func currentToken() -> String? {
        return NSUserDefaults.standardUserDefaults().valueForKey(TokenKey) as? String
    }
    
    func disactivateService() {
        configSocialNetwork(ActiveKey, enable: false)
    }
    
    func activateService() {
        configSocialNetwork(ActiveKey, enable: true)
    }
    
    func isServiceActive() -> Bool {
        return NSUserDefaults.standardUserDefaults().boolForKey(ActiveKey)
    }
    
    private func configSocialNetwork(key: String, enable: Bool) {
        NSUserDefaults.standardUserDefaults().setBool(enable, forKey: key)
    }
   
}