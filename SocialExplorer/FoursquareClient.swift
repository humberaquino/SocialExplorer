//
//  FoursquareClient.swift
//  SocialExplorer
//
//  Created by Humberto Aquino on 5/13/15.
//  Copyright (c) 2015 Humberto Aquino. All rights reserved.
//

import Foundation
import CoreLocation
import Alamofire
import SwiftyJSON
import ObjectMapper

class FoursquareClient: BaseSocialClient {
        
    let userSettings = UserSettings.sharedInstance()
    
    override func serviceActive() -> Bool {
        return userSettings.foursquare.isServiceActive()
    }
    
    override func currentToken() -> String? {
        return userSettings.instagram.currentToken()
    }
    
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


// MARK: - Constants

extension FoursquareClient {
    
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