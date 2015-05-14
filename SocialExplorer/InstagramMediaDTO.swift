//
//  InstagramMediaRecentDTO.swift
//  SocialExplorer
//
//  Created by Humberto Aquino on 5/7/15.
//  Copyright (c) 2015 Humberto Aquino. All rights reserved.
//

import Foundation
import ObjectMapper


// Instagram media subset DTO
// Ref: https://instagram.com/developer/endpoints/locations/
class InstagramMediaRecentDTO: Mappable {
    
    struct Keys {
        static let Id = "id"
        static let MediaType = "type"
        static let Tags = "tags"
        static let Caption = "caption.text"
        static let Likes = "likes.count"
        static let Link = "link"
        static let UserId = "user.id"
        static let CreatedTime = "created_time"
        static let Thumbnail = "images.thumbnail.url"
        static let Image = "images.standard_resolution.url"
    }
    
    var id: String?
    var mediaType: String?
    var tags: [String]?
    var caption: String?
    var likes: Int?
    var link: String?
    var userId: Int?
    var createdTime: NSDate?
    var thumbnail: String?
    var image: String?

    
    required init?(_ map: Map) {
        mapping(map)
    }
    
    func mapping(map: Map) {
        id <- map[Keys.Id]
        mediaType <- map[Keys.MediaType]
        tags <- map[Keys.Tags]
        caption <- map[Keys.Caption]
        likes <- map[Keys.Likes]
        link <- map[Keys.Link]
        userId <- map[Keys.UserId]
        createdTime <- (map[Keys.CreatedTime], DateTransform())
        thumbnail <- map[Keys.Thumbnail]
        image <- map[Keys.Image]
    }
    
}

