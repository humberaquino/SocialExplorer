//
//  InstagramMedia.swift
//  SocialExplorer
//
//  Created by Humberto Aquino on 5/6/15.
//  Copyright (c) 2015 Humberto Aquino. All rights reserved.
//

import Foundation
import CoreData
import SwiftyJSON


enum CDMediaState: String {
    case New = "new"
    case Favorited = "favorited"
}

@objc(CDMedia)

class CDMedia: NSManagedObject {
    
    static let ModelName = "Media"
    
    struct Defaults {
        static let State = "new"
    }
    
    // JSON Keys
    struct Keys {
        static let Id = "id"
        static let TypeName = "type"
        static let Likes = "likes"
        static let Likes_Count = "count"
        static let Link = "link"
        static let Tags = "tags"
        
        static let User = "user"
        static let User_Username = "username"
        static let User_ProfilePicture = "profile_picture"
        
        static let Images = "images"
        static let Images_StandardResolution = "standard_resolution"
        static let Images_Thumbnail = "thumbnail"
        static let Images_url = "url"
    }
    
    struct Types {
        static let Instagram = ""
    }
    
    struct PropertyKeys {
         static let ParentLocation = "parentLocation"
    }
    
    @NSManaged var id: String
    @NSManaged var thumbnailURL: String
    @NSManaged var userId: NSNumber
    @NSManaged var instagramURL: String
    @NSManaged var likesCount: Int
    @NSManaged var tags: String
    @NSManaged var type: String
    @NSManaged var standardResolutionURL: String
    @NSManaged var state: String
    
    @NSManaged var parentLocation: CDLocation

    override init(entity: NSEntityDescription, insertIntoManagedObjectContext context: NSManagedObjectContext?) {
        super.init(entity: entity, insertIntoManagedObjectContext: context)
    }
    
    // TODO: Change for DTO constructor?
    init(json: JSON, context: NSManagedObjectContext) {
        let entity = NSEntityDescription.entityForName(CDMedia.ModelName, inManagedObjectContext: context)!
        super.init(entity: entity, insertIntoManagedObjectContext: context)
        
        id = json[Keys.Id].stringValue
        
        type = json[Keys.TypeName].stringValue
                
        instagramURL = json[Keys.Link].stringValue
        likesCount = json[Keys.Likes][Keys.Likes_Count].intValue
        let tagsArray = json[Keys.Tags].arrayObject as! [String]
        tags = ",".join(tagsArray)
        
        userId = json[Keys.User][Keys.Id].intValue
        
        thumbnailURL = json[Keys.Images][Keys.Images_Thumbnail].stringValue
        standardResolutionURL = json[Keys.Images][Keys.Images_StandardResolution].stringValue
        
        state = CDMediaState.New.rawValue
    }
    
    init(dto: InstagramMediaRecentDTO, context: NSManagedObjectContext) {
        let entity = NSEntityDescription.entityForName(CDMedia.ModelName, inManagedObjectContext: context)!
        super.init(entity: entity, insertIntoManagedObjectContext: context)
        
        id = dto.id!
        type = dto.mediaType!
        instagramURL = dto.link!
        likesCount = dto.likes!
        tags = ",".join(dto.tags!)
        if let userId = dto.userId {
            self.userId =  NSNumber(integer: userId)
        }
        thumbnailURL = dto.thumbnail!
        standardResolutionURL = dto.image!
    }
    
    
    var title: String {
        // TODO: Use better info
        return "Instagram image with \(likesCount) likes"
    }
    
    var detail: String {
        return "Tags: \(tags)"
    }
    
    func toogleFavorited() {
        if isFavorited() {
            state = CDMediaState.New.rawValue
        } else {
            state = CDMediaState.Favorited.rawValue
        }
    }
    
    func isFavorited() -> Bool {
        if state == CDMediaState.Favorited.rawValue {
            return true
        } else {
            return false
        }
    }
    
    
}
