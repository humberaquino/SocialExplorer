//
//  BaseSocialClient.swift
//  SocialExplorer
//
//  Created by Humberto Aquino on 5/13/15.
//  Copyright (c) 2015 Humberto Aquino. All rights reserved.
//

import Foundation

// Common class to all social clients
class BaseSocialClient {
    
    var xRatelimitLimit: Int?
    var xRatelimitRemaining: Int?
    
    
    // MARK: Overide this
    
    func serviceActive() -> Bool {
        return false
    }
    
    func currentToken() -> String? {
        return nil
    }
    
    // MARK: Limits
    
    func updateLimitCount(response: NSHTTPURLResponse?) {
        self.xRatelimitLimit = response?.allHeaderFields[HeaderKeys.XRatelimitLimit] as? Int
        self.xRatelimitRemaining = response?.allHeaderFields[HeaderKeys.XRatelimitRemaining] as? Int
    }
    
    // MARK: OAuth
    
    func execWithToken(callback:(token:String!, error: NSError!) -> Void) {
        // 1. Check instagram for its token and if is available
        if serviceActive() {
            // instagram is available
            if let token = currentToken() {
                // Has a token -> Start the request
                callback(token: token, error: nil)
            } else {
                // No token
                logger.error("Instagram does not have a token")
                 callback(token: nil, error: ErrorUtils.errorForInstagramWithoutToken())
            }
        } else {
            // 1.b NOT available
            // Do nothing
            logger.debug("Instagram is disabled")
            callback(token: nil, error: ErrorUtils.errorForInstagramDisabled())
        }
    }
    
    
}

extension BaseSocialClient {
    struct HeaderKeys {
        static let XRatelimitLimit = "X-Ratelimit-Limit"
        static let XRatelimitRemaining = "X-Ratelimit-Remaining"
    }
}