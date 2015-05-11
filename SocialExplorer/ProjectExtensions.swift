//
//  Config.swift
//  SocialExplorer
//
//  Created by Humberto Aquino on 5/3/15.
//  Copyright (c) 2015 Humberto Aquino. All rights reserved.
//

import Foundation


extension CoreDataStackManager {
    struct Constants {
        static let SQLiteFilename = "SocialExplorer.sqlite"
        static let ModelName = "SocialExplorerModel"
        static let ModelExtension = "momd"
        static let ImagesDirectory = "images"
    }
    struct Error {
        static let Domain = "CoreData"
        // Error while trying to initialize the PersistentStoreCoordiantor
        // Hint: Check the Core data stack
        static let PersistentStoreCoordiantorInitialization = 5000
    }
}

// MARK: - Constants

extension DiscoverMapViewController {
    struct UI {
        static let MinimumPressDuration:NSTimeInterval = 2
    }
}

extension SyncManager {
    struct Constants {
        static let SyncQueueName = "me.humberaquino.SyncMaster"
    }
}

// FIXME: This is no extension
struct Instagram {
    
    struct URL {
        static let Authorize = "https://api.instagram.com/oauth/authorize/" //?client_id=CLIENT-ID&redirect_uri=REDIRECT-URI&response_type=code
        
        // Builds authorizarion URL 
        // https://api.instagram.com/oauth/authorize/?client_id=CLIENT-ID&redirect_uri=REDIRECT-URI&response_type=code
        static func buildAuthorizeClientURL() -> String {
            
            let parameters = [
                ParameterKeys.ClientId: Config.Instagram.ClientId,
                ParameterKeys.RedirectURI: Config.Instagram.RedirectURI,
                ParameterKeys.ResponseType: ParameteValues.Code
            ]
            
            let escapedParameters = HTTPUtils.escapedParameters(parameters)
            
            let url = "\(Authorize)\(escapedParameters)"
            return url
        }
    }
    
    struct ParameterKeys {
        static let ClientId = "client_id"
        static let RedirectURI = "redirect_uri"
        static let ResponseType = "response_type"
    }
    
    struct ParameteValues {
        static let Code = "code"
        static let Token = "token"
    }
    
}




