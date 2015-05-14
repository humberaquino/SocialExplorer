//
//  FoursquarePhotoDTO.swift
//  SocialExplorer
//
//  Created by Humberto Aquino on 5/13/15.
//  Copyright (c) 2015 Humberto Aquino. All rights reserved.
//

import Foundation
import ObjectMapper

class FoursquarePhotoDTO: Mappable {
    
    // Ref:  https://developer.foursquare.com/docs/responses/photo
    let ThumbnailSize = 100
    
    struct Keys {
        static let Id = "id"
        static let CreatedTime = "created_time"
        static let Prefix = "prefix"
        static let Suffix = "suffix"
         static let Width = "width"
         static let Height = "height"
    }
    
    var id: String?
    var createdTime: NSDate?
    
    var prefix: String?
    var suffix: String?
    var width: Int?
    var height: Int?
    
//    var parent: InstagramLocationDTO?
    
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
    }
    
    func imagePath() -> String? {
        if let prefix = prefix, suffix = suffix, width = width, height = height {
            return "\(prefix)\(width)x\(height)\(suffix)"
        }
        return nil
    }
    
    func thumbnailImagePath() -> String? {
        if let prefix = prefix, suffix = suffix, width = width, height = height {
            return "\(prefix)\(ThumbnailSize)x\(ThumbnailSize)\(suffix)"
        }
        return nil
    }
    
}