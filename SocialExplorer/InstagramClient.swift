
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
    
    
    // Won't work anymore
    // http://developers.instagram.com/post/116410697261/publishing-guidelines-and-signed-requests
    func postLikeMedia(mediaId: String, completion:(error: NSError?) -> Void) {
        self.execWithToken { (token, error) -> Void in
            let parameters: [String: AnyObject] = [
                ParameterKeys.AccessToken: token
            ]
            
            // 1. Do the request to get the list of medias for the locationId
            Alamofire.request(.POST, URI.LikeMedia(mediaId), parameters: parameters).response {
                (request, response, data, error) in
                if let error = error {
                    // Request error
                    completion(error: error)
                    return
                }
                
                // 2. Check for responses taht are valid but return errors. E.g. limit exceeded
                self.updateLimitCount(response)
                if let remainingRequests = self.xRatelimitRemaining {
                    if remainingRequests <= 0 {
                        // Error: Request limit exceeded for client
                        let error = ErrorUtils.errorForLimitExceeded()
                        completion(error: error)
                        return
                    }
                }
                
                // 3. Parse the "code" element
                let jsonData = data as! NSData
                let json = JSON(data: jsonData)
                let code = json["meta"]["code"].intValue
                
                if code != 200 {
                    completion(error: nil)
                } else {
                    let error = ErrorUtils.errorForOAuthPermissionsException(code, message: json["meta"]["error_message"].string)
                    completion(error: error)
                }
                
                
            }
        }
    }
    
    func isMediaLiked(mediaId: String, completion:(isLiked: Bool, error: NSError?) -> Void) {
        getMedia(mediaId, completion: { (json, error) -> Void in
            if let error = error {
                completion(isLiked: false, error: error)
                return
            }
            
            let isLiked = json["user_has_liked"].boolValue
            completion(isLiked: isLiked, error: nil)
        })
    }
    
    func getMedia(mediaId: String, completion:(json: JSON!, error: NSError?) -> Void) {
        self.execWithToken { (token, error) -> Void in
            let parameters: [String: AnyObject] = [
                ParameterKeys.AccessToken: token
            ]
            
            // 1. Do the request to get the list of medias for the locationId
            Alamofire.request(.GET, URI.Media(mediaId), parameters: parameters).response {
                (request, response, data, error) in
                if let error = error {
                    // Request error
                    completion(json: nil, error: error)
                    return
                }
                
                // 2. Check for responses taht are valid but return errors. E.g. limit exceeded
                self.updateLimitCount(response)
                if let remainingRequests = self.xRatelimitRemaining {
                    if remainingRequests <= 0 {
                        // Error: Request limit exceeded for client
                        let error = ErrorUtils.errorForLimitExceeded()
                        completion(json: nil, error: error)
                        return
                    }
                }
                
                // 3. Parse the "code" element
                let jsonData = data as! NSData
                let baseJson = JSON(data: jsonData)
                let json = baseJson["data"]
                
                completion(json: json, error: nil)
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
        static let BaseSecureURL = "https://api.instagram.com/v1"
        static let LocationSearch = "\(BaseSecureURL)/locations/search"
        
        static func LocationMediaRecentWithLocationId(locationId: String) -> String {
            return "\(BaseSecureURL)/locations/\(locationId)/media/recent"
        }
        static func Media(mediaId: String) -> String {
            return "\(BaseSecureURL)/media/\(mediaId)"
        }
        
        static func LikeMedia(mediaId: String) -> String {
            return "\(BaseSecureURL)/media/\(mediaId)/likes"
        }
    }
    
}

