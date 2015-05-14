//
//  Config.swift
//  SocialExplorer
//
//  Created by Humberto Aquino on 5/3/15.
//  Copyright (c) 2015 Humberto Aquino. All rights reserved.
//

import Foundation
import XCGLogger

// Configuration per project. Contain data that we know at compile time and almost always change 
// in different environments. E.g. development, production, testing

struct Config {
    
    struct Foursquare {
        static let ClientId = "SGEUNLGUMKP4ZEOK1YTCQUMQPOH1FM1SZBUNOIUGFUU33E2G"
        static let ClientSecret = "UUMP15CCXSKY2BTJSAU2LAXQXY2E1GCCK0Z1SDE3DRIMKUQE"
        static let RedirectURI = "SocialExplorer://"
        static let VersionAPI = "20140701"
        static let SearchVenueLimit = 10
        static let SearchVenuePhotoLimit = 10
    }
    
    // Instagram constants
    struct Instagram {
        static let ClientId = "939662edefdf44b4ad227ba1b5e24b21"
        static let ClientSecret = "9fc9111fd65945afb555f2c2ab089e81"
        static let RedirectURI = "SocialExplorer://"
    }
        
    // Logger configuration
    struct Logger {
        static let LogLevel = XCGLogger.LogLevel.Debug
        static let ShowLogLevel = true
        static let ShowFileNames = false
        static let ShowLineNumbers = true
        static let WriteToFile:String! = nil
        static let FileLogLevel = XCGLogger.LogLevel.Debug
    }
    
}