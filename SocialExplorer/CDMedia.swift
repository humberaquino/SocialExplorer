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
import CoreLocation

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
        static let State = "state"
    }
    
    @NSManaged var id: String
    @NSManaged var thumbnailURL: String
    @NSManaged var userId: NSNumber
    @NSManaged var instagramURL: String
    @NSManaged var likesCount: Int
    @NSManaged var tags: String?
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
        
        tags = joinTags(dto.tags)
        
        if let userId = dto.userId {
            self.userId =  NSNumber(integer: userId)
        }
        thumbnailURL = dto.thumbnail!
        standardResolutionURL = dto.image!
        
        state = CDMediaState.New.rawValue
    }
    
    
    var title: String {
        // TODO: Use better info
        return "Instagram image with \(likesCount) likes"
    }
    
    var detail: String {
        if let tags = self.tagsAsCommaSeparatedString() {
            return tags
        } else {
            return "No tags"
        }
        
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
    
    
    func tagsAsCommaSeparatedString() -> String? {
        if let tagsList = self.tagsAsArray() {
            let count = tagsList.count
            if count == 0 {
                return nil
            } else {
                let first = tagsList[0]
                if count == 1 {
                    return " #\(first)"
                } else {
                    var result = ""
                    for var i = 1; i < count; ++i {
                        result += " #\(tagsList[i])"
                    }
                    return result
                }
            }
        }
        return nil
    }
    
    func tagsAsArray() -> [String]? {
        if let tags = self.tags {
            if let dataFromString = tags.dataUsingEncoding(NSUTF8StringEncoding, allowLossyConversion: false) {
                let json = JSON(data: dataFromString)
                return json.arrayObject as? [String]
            }
        }
        return nil
    }
    
    // Workaround to join strings. 
    // I did this because I had issues with ",".join([String]) when some item in the array has emoji
    // It blocked the thread and the syncronization didn't end
    func joinTags(dtoTags: [String]?) -> String? {
        let json = JSON(dtoTags!)
        let string  = json.rawString()
        return string
    }
    
    var coordinate: CLLocationCoordinate2D {
        return parentLocation.coordinate
    }
}
