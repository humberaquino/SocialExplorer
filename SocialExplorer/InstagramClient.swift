
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

class InstagramClient: BaseSocialClient {
    
    
    let userSettings = UserSettings.sharedInstance()
    
    override func serviceActive() -> Bool {
        return userSettings.instagram.isServiceActive()
    }
    
    override func currentToken() -> String? {
        return userSettings.instagram.currentToken()
    }
        
    // MARK: - Base requests
    
    // https://instagram.com/developer/endpoints/locations/
    func requestLocations(coordiante: CLLocationCoordinate2D, completion: (instagramLocationDTOList: [InstagramLocationDTO]!, error: NSError!) -> Void) {
        
        self.execWithToken { (token, error) -> Void in
            if error != nil {
                completion(instagramLocationDTOList: nil, error: error)
                return
            }
            
            let parameters: [String: AnyObject] = [
                ParameterKeys.Latitude: coordiante.latitude,
                ParameterKeys.Longitude: coordiante.longitude,
                ParameterKeys.AccessToken: token,
                ParameterKeys.Accuracy: Config.Instagram.Accuracy
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


// MARK: - Constants

extension InstagramClient {
    
    struct ParameterKeys {
        static let Latitude = "lat"
        static let Longitude = "lng"
        static let AccessToken = "access_token"
        static let Accuracy = "distance"
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

