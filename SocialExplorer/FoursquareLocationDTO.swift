//
//  FoursquareLocationDTO.swift
//  SocialExplorer
//
//  Created by Humberto Aquino on 5/13/15.
//  Copyright (c) 2015 Humberto Aquino. All rights reserved.
//

import Foundation

import ObjectMapper

class FoursquareLocationDTO: Mappable {
    
    struct Keys {
        static let Id = "id"
        static let Latitude = "location.lat"
        static let Longitude = "location.lng"
        static let Name = "name"
    }
    
    var id: String?
    var latitude: Double?
    var longitude: Double?
    var name: String?
    
//    var mediaList: [InstagramMediaRecentDTO] = []
    
    
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
    
//    func addMedia(media: InstagramMediaRecentDTO) {
//        media.parent = self
//        mediaList.append(media)
//    }
//    
//    func addMedias(mediaList: [InstagramMediaRecentDTO]) {
//        for media in mediaList {
//            addMedia(media)
//        }
//    }
    
    func asDict() -> [String: AnyObject] {
        let dict: [String: AnyObject] = [
            CDLocation.Keys.Id: self.id!,
            CDLocation.Keys.Latitude: self.latitude!,
            CDLocation.Keys.Longitude: self.longitude!,
            CDLocation.Keys.Name: self.name!,
            CDLocation.Keys.LocationType: SocialNetworkType.Foursquare.rawValue
        ]
        return dict
    }
}