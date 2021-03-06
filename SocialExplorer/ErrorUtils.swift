//
//  ErrorUtils.swift
//  SocialExplorer
//
//  Created by Humberto Aquino on 5/7/15.
//  Copyright (c) 2015 Humberto Aquino. All rights reserved.
//

import Foundation



struct ErrorUtils {
    
    
    static func errorForOAuthPermissionsException(code: Int, message: String?) -> NSError {
        return errorWithMessage("Instagram permission error (Code: \(code). \(message))", domain:.OAuth, code:.InstagramOAuthException)
    }
    
    static func errorForInstagramDisabled() -> NSError {
        return errorWithMessage("Instagram disabled", domain:.Service, code:.InstagramServiceDisabled)
    }
    
    static func errorForInstagramWithoutToken() -> NSError {
        return errorWithMessage("Instagram does not have a token", domain:.Service, code:.InstagramDoesNotHaveToken)
    }
    
    

    // MARK: Geocoder
    
    static func errorForGeocoderWithoutPlacemarks() -> NSError {
        return errorWithMessage("Geocoder returned empty placemarks for location", domain:.Geocoder, code:.GeocoderReturnedEmptyPlacemarks)
    }
    
    // MARK: Instagram
    
    static func errorForLimitExceeded() -> NSError {
        return errorWithMessage("Instagram limit exceeded for client", domain:.InstagramClient, code:.LimitExceeded)
    }
    
    // MARK: Generic
    
    static func errorWithMessage(message: String, domain: ErrorDomain, code: ErrorCode) -> NSError {
        let userInfo:[NSObject: AnyObject] = [NSLocalizedDescriptionKey : message]
        return NSError(domain: domain.rawValue, code: code.rawValue, userInfo: userInfo)
    }
    
    
}

// MARK: Error enums

enum ErrorDomain: String {
    case InstagramClient = "InstagramClient"
    case Geocoder = "Geocoder"
    case Service = "Service"
    case OAuth = "OAuth"
}

enum ErrorCode: Int {
    case LimitExceeded = 100
    
    case GeocoderReturnedEmptyPlacemarks = 200
    
    case InstagramServiceDisabled = 300
    case InstagramOAuthException = 301
    case InstagramDoesNotHaveToken = 302
}