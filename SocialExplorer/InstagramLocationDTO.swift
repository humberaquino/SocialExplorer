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

// {
//    "id": "788029",
//    "latitude": 48.858844300000001,
//    "longitude": 2.2943506,
//    "name": "Eiffel Tower, Paris"
// }

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
    
    var mediaList: [InstagramMediaRecentDTO] = []
    
    
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
    
    func addMedia(media: InstagramMediaRecentDTO) {
        media.parent = self
        mediaList.append(media)
    }
    
    func addMedias(mediaList: [InstagramMediaRecentDTO]) {
        for media in mediaList {
            addMedia(media)
        }
    }
}