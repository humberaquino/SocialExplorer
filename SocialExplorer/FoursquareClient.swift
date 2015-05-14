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
           
    //
    func requestVenues(coordiante: CLLocationCoordinate2D, completion: (foursquareLocationDTOList: [FoursquareLocationDTO]!, error: NSError!) -> Void) {                
        
        let latitudeAndLongitude = "\(coordiante.latitude),\(coordiante.longitude)"
        
        let parameters: [String: AnyObject] = [
            ParameterKeys.LatitudeAndLongitude: latitudeAndLongitude,
            ParameterKeys.ClientId: Config.Foursquare.ClientId,
            ParameterKeys.ClientSecret: Config.Foursquare.ClientSecret,
            ParameterKeys.VersionAPI: Config.Foursquare.VersionAPI,
            ParameterKeys.Limit: Config.Foursquare.SearchVenueLimit,
            ParameterKeys.Accuracy: Config.Foursquare.Accuracy
        ]
        
        
        // 1. Request the location list for the provided coordinate
        Alamofire.request(.GET, URI.VenueSearch, parameters: parameters).response {
            (request, response, data, error) in
            if let error = error {
                // Request error
                completion(foursquareLocationDTOList: nil, error: error)
                return
            }
            
            // 2. Check for responses taht are valid but return errors. E.g. limit exceeded
            self.updateLimitCount(response)
            if let remainingRequests = self.xRatelimitRemaining {
                if remainingRequests <= 0 {
                    // Error: Request limit exceeded for client
                    let error = ErrorUtils.errorForLimitExceeded()
                    completion(foursquareLocationDTOList: nil, error: error)
                    return
                }
            }
            
            // 3. Parse the "data" element
            let jsonData = data as! NSData
            let json = JSON(data: jsonData)
            // TODO: Key for strings
            let venuesList = json["response"]["venues"].arrayValue
            
            var foursquareLocationDTOList: [FoursquareLocationDTO] = []
            
            for venueElement in venuesList {
                let venueElementString = venueElement.rawString()
                if let foursquareLocationDTO = Mapper<FoursquareLocationDTO>().map(venueElementString!) {
                    foursquareLocationDTOList.append(foursquareLocationDTO)
                } else {
                    logger.warning("Foursquare location skipped")
                }
            }
            
            // Success. Let's map the JSON response and complete
            completion(foursquareLocationDTOList: foursquareLocationDTOList, error: nil)
        }
        
        
    }
    

    func requestVenueInfoBy(venueId: String, completion: (foursquarePhotoDTOList: [FoursquarePhotoDTO]!, error: NSError!) -> Void) {
        
        let parameters: [String: AnyObject] = [
            ParameterKeys.ClientId: Config.Foursquare.ClientId,
            ParameterKeys.ClientSecret: Config.Foursquare.ClientSecret,
            ParameterKeys.VersionAPI: Config.Foursquare.VersionAPI,
            ParameterKeys.Limit: Config.Foursquare.SearchVenuePhotoLimit,
        ]
        
        // 1. Do the request to get the list of medias for the locationId
        Alamofire.request(.GET, URI.VenueMediaPhotos(venueId), parameters: parameters).response {
            (request, response, data, error) in
            if let error = error {
                // Request error
                completion(foursquarePhotoDTOList: nil, error: error)
                return
            }
            
            // 2. Check for responses taht are valid but return errors. E.g. limit exceeded
            self.updateLimitCount(response)
            if let remainingRequests = self.xRatelimitRemaining {
                if remainingRequests <= 0 {
                    // Error: Request limit exceeded for client
                    let error = ErrorUtils.errorForLimitExceeded()
                    completion(foursquarePhotoDTOList: nil, error: error)
                    return
                }
            }
            
            // 3. Parse the "response" element
            let jsonData = data as! NSData
            let json = JSON(data: jsonData)
            let jsonPhotoList = json["response"]["photos"]["items"].arrayValue
            
            // 4. Add every element in the data array
            var result:[FoursquarePhotoDTO] = []
            for photoElement in jsonPhotoList {
                let photoElementString = photoElement.rawString()
                if let foursquareVenueDTO = Mapper<FoursquarePhotoDTO>().map(photoElementString!) {
                    result.append(foursquareVenueDTO)
                } else {
                    logger.warning("Foursquare recent media skipped")
                }
            }
            // Success
            completion(foursquarePhotoDTOList: result, error: nil)
        }
    }
    
    
}


// MARK: - Constants

extension FoursquareClient {
    
    struct ParameterKeys {
        static let LatitudeAndLongitude = "ll"
        static let VersionAPI = "v"
        static let ClientId = "client_id"
        static let ClientSecret = "client_secret"
        static let Limit = "limit"
        static let Accuracy = "llAcc"
    }
    
    struct ResponseKeys {
        static let Data = "data"
        static let Id = "id"
    }
    
    struct URI {
        static let BaseSecureURL = "https://api.foursquare.com/v2"
        static let VenueSearch = "\(BaseSecureURL)/venues/search"
        
        static func VenueMediaPhotos(venueId: String) -> String {
            return "\(BaseSecureURL)/venues/\(venueId)/photos"
        }
       
    }
    
}