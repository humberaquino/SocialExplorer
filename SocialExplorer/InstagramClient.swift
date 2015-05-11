
//  InstagramClient.swift
//  SocialExplorer
//
//  Created by Humberto Aquino on 5/5/15.
//  Copyright (c) 2015 Humberto Aquino. All rights reserved.
//

import Foundation
import CoreLocation
import Alamofire
import SwiftyJSON
import ObjectMapper

class InstagramClient {
    
    
    var xRatelimitLimit: Int?
    var xRatelimitRemaining: Int?
    
    let userSettings = UserSettings.sharedInstance()
    
    
//    func downloadInstagramLocations(locationCoordinates: [CLLocationCoordinate2D],
//        completion: (locationDTOs:[InstagramLocationDTO]!, error: NSError!) -> Void) {
//            
//            if locationCoordinates.count == 0 {
//                completion(locationDTOs: [], error: nil)
//                return
//            }
//            
//            // 1. For every coordinate get the list of locatations
//            
//            
//            var locationDTOs = SynchronizedArray<InstagramLocationDTO>()
//            var errorList = SynchronizedArray<NSError>()
//            
//            let locationsGroup = dispatch_group_create()
//                        
//            
//            for coordinate in locationCoordinates {
//                dispatch_group_enter(locationsGroup)
//                
//                requestLocations(coordinate, completion: { (instagramLocationDTOList, error) -> Void in
//                    if let error = error {
//                       errorList.append(error)
//                    } else {
//                       locationDTOs.append(ins)
//                    }
//                    
//                    dispatch_group_leave(locationsGroup)
//                })
//                
//                
//            }
//            
//            
//            
//            dispatch_group_notify(locationsGroup, SyncManager.sharedInstance().SyncQueue) {
//                logger.debug("Instagram location group complete")
//                completion(locationDTOs: locationDTOs, error: error)
//            }
//            
//            
//            for reference in newReferences {
//                
//            }
//    }
    
    
//    func searchLocationsWithMedia
    
    
//    func searchLocationsAndMediaByLocation(coordiante: CLLocationCoordinate2D, completion: (instagramLocationDTOList: [InstagramLocationDTO]!, error: NSError!) -> Void) {
//        
//        // 1. Get the list of locations near the provided coordinate
//        requestLocations(coordiante, completion: {
//            (instagramLocationDTOList, error) -> Void in
//            
//            var successMediaRecent: [String: JSON]  = [String : JSON]()
//            var errorMediaRecent: [String: NSError?] = [String : NSError?]()
//            
//            if error != nil {
//                // Error in the location request
//                completion(instagramLocationDTOList: nil, error: error)
//                return
//            }
//            
//            if instagramLocationDTOList.count == 0 {
//                // Complete but without data
//                completion(instagramLocationDTOList: instagramLocationDTOList, error: nil)
//                return
//            }
//            
//            
//            logger.debug("Searching \(instagramLocationDTOList.count) locations in group")
//            var lastError: NSError?            
//            var locationsGroup = dispatch_group_create()
//            for instagramLocationDTO in instagramLocationDTOList {
//                
//                let locationId = instagramLocationDTO.id!
//                
//                logger.debug("Entering group for location \(locationId)")
//                dispatch_group_enter(locationsGroup)
//
//                
//                // Download a location
//                self.requestLocationMediaRecent(locationId) {
//                    (instagramMediaDTOList: [InstagramMediaRecentDTO]!, error: NSError!) in
//                    
//                    if error != nil {
//                        logger.error("Error in group. Location \(locationId): \(error)")
//                        lastError = error
//                    } else {
//                        instagramLocationDTO.addMedias(instagramMediaDTOList)
//                    }
//                    
//                    logger.debug("Leaving group for location \(locationId)")
//                    dispatch_group_leave(locationsGroup)
//                }
//            }
//            
//            dispatch_group_notify(locationsGroup, GlobalUserInitiatedQueue) {
//                logger.debug("Group completed")
//                completion(instagramLocationDTOList: instagramLocationDTOList, error: lastError)
//            }
//            
//            
//        })
//    }
    
    // MARK: - Base requests
    
    // https://api.instagram.com/v1/locations/search?lat=48.858844&lng=2.294351&access_token=ACCESS-TOKEN
    func requestLocations(coordiante: CLLocationCoordinate2D, completion: (instagramLocationDTOList: [InstagramLocationDTO]!, error: NSError!) -> Void) {
        
        self.execWithToken { (token, error) -> Void in
            if error != nil {
                completion(instagramLocationDTOList: nil, error: error)
                return
            }
            
            let parameters: [String: AnyObject] = [
                ParameterKeys.Latitude: coordiante.latitude,
                ParameterKeys.Longitude: coordiante.longitude,
                ParameterKeys.AccessToken: token
            ]
            

            // 1. Request the location list for the provided coordinate
            Alamofire.request(.GET, URI.LocationSearch, parameters: parameters).response {
                (request, response, data, error) in
                if let error = error {
                    // Request error
                    completion(instagramLocationDTOList: nil, error: error)
                    return
                }
                
                // 2. Check for responses taht are valid but return errors. E.g. limit exceeded
                self.updateLimitCount(response)
                if let remainingRequests = self.xRatelimitRemaining {
                    if remainingRequests <= 0 {
                        // Error: Request limit exceeded for client
                        let error = ErrorUtils.errorForLimitExceeded()
                        completion(instagramLocationDTOList: nil, error: error)
                        return
                    }
                }
                
                // 3. Parse the "data" element
                let jsonData = data as! NSData
                let json = JSON(data: jsonData)
                let jsonDataList = json["data"].arrayValue
                
                var instagramLocationDTOList: [InstagramLocationDTO] = []
                
                for dataElement in jsonDataList {
                    let dataElementString = dataElement.rawString()
                    if let instagramLocationDTO = Mapper<InstagramLocationDTO>().map(dataElementString!) {
                        instagramLocationDTOList.append(instagramLocationDTO)
                    } else {
                        logger.warning("Instagram location skipped")
                    }
                }
                
                // Success. Let's map the JSON response and complete
                completion(instagramLocationDTOList: instagramLocationDTOList, error: nil)
            }
        }
        
    }
    
    // https://api.instagram.com/v1/locations/{location-id}/media/recent?access_token=ACCESS-TOKEN
    func requestMediaRecentForLocationId(locationId: String, completion: (instagramMediaDTOList: [InstagramMediaRecentDTO]!, error: NSError!) -> Void) {
        
        self.execWithToken { (token, error) -> Void in
            if error != nil {
                completion(instagramMediaDTOList: nil, error: error)
                return
            }
            
            let parameters: [String: AnyObject] = [
                ParameterKeys.AccessToken: token
            ]
            
            // 1. Do the request to get the list of medias for the locationId
            Alamofire.request(.GET, URI.LocationMediaRecentWithLocationId(locationId), parameters: parameters).response {
                (request, response, data, error) in
                if let error = error {
                    // Request error
                    completion(instagramMediaDTOList: nil, error: error)
                    return
                }
                
                // 2. Check for responses taht are valid but return errors. E.g. limit exceeded
                self.updateLimitCount(response)
                if let remainingRequests = self.xRatelimitRemaining {
                    if remainingRequests <= 0 {
                        // Error: Request limit exceeded for client
                        let error = ErrorUtils.errorForLimitExceeded()
                        completion(instagramMediaDTOList: nil, error: error)
                        return
                    }
                }
                
                // 3. Parse the "data" element
                let jsonData = data as! NSData
                let json = JSON(data: jsonData)
                let jsonDataList = json["data"].arrayValue
                
                // 4. Add every element in the data array
                var result:[InstagramMediaRecentDTO] = []
                for dataElement in jsonDataList {
                    let dataElementString = dataElement.rawString()
                    if let instagramMediaDTO = Mapper<InstagramMediaRecentDTO>().map(dataElementString!) {
                        result.append(instagramMediaDTO)
                    } else {
                        logger.warning("Instagram recent media skipped")
                    }
                }
                // Success
                completion(instagramMediaDTOList: result, error: nil)
            }
            
        }
        
    }
    
}


// MARK: - Utils

extension InstagramClient {
    
    // MARK: Limits
    
    func updateLimitCount(response: NSHTTPURLResponse?) {
        self.xRatelimitLimit = response?.allHeaderFields[HeaderKeys.XRatelimitLimit] as? Int
        self.xRatelimitRemaining = response?.allHeaderFields[HeaderKeys.XRatelimitRemaining] as? Int
    }
 
    // MARK: OAuth
    
    func execWithToken(callback:(token:String!, error: NSError!) -> Void) {
        // 1. Check instagram for its token and if is available
        if userSettings.instagram.isServiceActive() {
            // instagram is available
            if let token = userSettings.instagram.currentToken() {
                // Has a token -> Start the request
                callback(token: token, error: nil)
            } else {
                // No token
                // TODO: Do OAuth request
                logger.info("Instagram does not have a token")
            }
        } else {
            // 1.b NOT available
            // Do nothing
            logger.debug("Instagram is disabled")
            callback(token: nil, error: ErrorUtils.errorForInstagramDisabled())
        }
    }
    
    
}

// MARK: - Constants

extension InstagramClient {
    
    struct HeaderKeys {
        static let XRatelimitLimit = "X-Ratelimit-Limit"
        static let XRatelimitRemaining = "X-Ratelimit-Remaining"
    }
    
    struct ParameterKeys {
        static let Latitude = "lat"
        static let Longitude = "lng"
        static let AccessToken = "access_token"
    }
    
    struct ResponseKeys {
        static let Data = "data"
        static let Id = "id"
    }
    
    struct URI {
        static let LocationSearch = "https://api.instagram.com/v1/locations/search"
        
        static func LocationMediaRecentWithLocationId(locationId: String) -> String {
            return "https://api.instagram.com/v1/locations/\(locationId)/media/recent"
        }
    }
    
}

