//
//  InstagramLocation.swift
//  SocialExplorer
//
//  Created by Humberto Aquino on 5/7/15.
//  Copyright (c) 2015 Humberto Aquino. All rights reserved.
//

import Foundation
import ObjectMapper

// Represents a single instagram location
// Ref: https://instagram.com/developer/endpoints/locations/

class InstagramLocationDTO: Mappable {
    
    struct Keys {
        static let Id = "id"
        static let Latitude = "latitude"
        static let Longitude = "longitude"
        static let Name = "name"
    }
    
    var id: String?
    var latitude: Double?
    var longitude: Double?
    var name: String?
    
    required init?(_ map: Map) {
        mapping(map)
    }
    
    //MARK: Mappable
    
    func mapping(map: Map) {
        id <- map[Keys.Id]
        latitude <- map[Keys.Latitude]
        longitude <- map[Keys.Longitude]
        name <- map[Keys.Name]
    }

    func asDict() -> [String: AnyObject] {
        let dict: [String: AnyObject] = [
            CDLocation.Keys.Id: self.id!,
            CDLocation.Keys.Latitude: self.latitude!,
            CDLocation.Keys.Longitude: self.longitude!,
            CDLocation.Keys.Name: self.name!,
            CDLocation.Keys.LocationType: SocialNetworkType.Instagram.rawValue
        ]
        return dict
    }
}