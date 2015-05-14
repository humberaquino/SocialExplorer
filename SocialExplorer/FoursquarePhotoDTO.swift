//
//  FoursquarePhotoDTO.swift
//  SocialExplorer
//
//  Created by Humberto Aquino on 5/13/15.
//  Copyright (c) 2015 Humberto Aquino. All rights reserved.
//

import Foundation
import ObjectMapper

// Foursquare Photo Response subset DTO
// Ref: https://developer.foursquare.com/docs/responses/photo
class FoursquarePhotoDTO: Mappable {

    let ThumbnailSize = 100
    
    struct Keys {
        static let Id = "id"
        static let CreatedTime = "createdAt"
        static let Prefix = "prefix"
        static let Suffix = "suffix"
        static let Width = "width"
        static let Height = "height"
        static let FirstName = "user.firstName"
        static let LastName = "user.lastName"
    }
    
    var id: String?
    var createdTime: NSDate?
    var prefix: String?
    var suffix: String?
    var width: Int?
    var height: Int?
    var firstName: String?
    var lastName: String?
    
    required init?(_ map: Map) {
        mapping(map)
    }
    
    func mapping(map: Map) {
        id <- map[Keys.Id]
        createdTime <- (map[Keys.CreatedTime], DateTransform())
        prefix <- map[Keys.Prefix]
        suffix <- map[Keys.Suffix]
        width <- map[Keys.Width]
        height <- map[Keys.Height]
        firstName <- map[Keys.FirstName]
        lastName <- map[Keys.LastName]
    }
    
    // String URL path of the image
    func imagePath() -> String? {
        if let prefix = prefix, suffix = suffix, width = width, height = height {
            return "\(prefix)\(width)x\(height)\(suffix)"
        }
        return nil
    }
    
    // String URL path of the thumbnail image
    func thumbnailImagePath() -> String? {
        if let prefix = prefix, suffix = suffix, width = width, height = height {
            return "\(prefix)\(ThumbnailSize)x\(ThumbnailSize)\(suffix)"
        }
        return nil
    }
    
    var caption: String {
        if let firstName = firstName, lastName = lastName {
            return "\(firstName) \(lastName)"
        } else {
            return "Foursquare photo"
        }
    }
    
}