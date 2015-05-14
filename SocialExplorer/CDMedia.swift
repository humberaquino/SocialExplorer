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

    struct PropertyKeys {
        static let ParentLocation = "parentLocation"
        static let State = "state"
        static let Type = "type"
    }
    
    @NSManaged var id: String
    @NSManaged var thumbnailURL: String
    @NSManaged var caption: String?
    @NSManaged var tags: String?
    @NSManaged var type: String
    @NSManaged var imageURL: String
    @NSManaged var state: String
    @NSManaged var creationDate: NSDate?
    
    @NSManaged var parentLocation: CDLocation

    override init(entity: NSEntityDescription, insertIntoManagedObjectContext context: NSManagedObjectContext?) {
        super.init(entity: entity, insertIntoManagedObjectContext: context)
    }
    
    init(dto: InstagramMediaRecentDTO, context: NSManagedObjectContext) {
        let entity = NSEntityDescription.entityForName(CDMedia.ModelName, inManagedObjectContext: context)!
        super.init(entity: entity, insertIntoManagedObjectContext: context)
        
        id = dto.id!
        type = SocialNetworkType.Instagram.rawValue
        caption = dto.caption
        tags = joinTags(dto.tags)
        thumbnailURL = dto.thumbnail!
        imageURL = dto.image!
        state = CDMediaState.New.rawValue
        creationDate = dto.createdTime
    }
    
    init(dto: FoursquarePhotoDTO, context: NSManagedObjectContext) {
        let entity = NSEntityDescription.entityForName(CDMedia.ModelName, inManagedObjectContext: context)!
        super.init(entity: entity, insertIntoManagedObjectContext: context)
        
        id = dto.id!
        type = SocialNetworkType.Foursquare.rawValue
        caption = dto.caption
        imageURL = dto.imagePath()!
        thumbnailURL = dto.thumbnailImagePath()!
        state = CDMediaState.New.rawValue
        creationDate = dto.createdTime
    }
    
    
    var title: String {
        if let caption = caption {
            return caption
        } else {
            return "\(type) photo"
        }
    }
    
    
    var detail: String {
        if let tags = self.tagsAsCommaSeparatedString() {
            return tags
        } else {
            if type == SocialNetworkType.Foursquare.rawValue {
                return ""
            } else {
                return "No tags"
            }
        }
    }
    
    var coordinate: CLLocationCoordinate2D {
        return parentLocation.coordinate
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
    
    // MARK:  Utils
    
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
   
}
