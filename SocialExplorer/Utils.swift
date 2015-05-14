//
//  Utils.swift
//  SocialExplorer
//
//  Created by Humberto Aquino on 5/3/15.
//  Copyright (c) 2015 Humberto Aquino. All rights reserved.
//

import Foundation

struct HTTPUtils {
    // Helper: Given a dictionary of parameters, convert to a string for a url
    static func escapedParameters(parameters: [String : AnyObject]) -> String {
        
        var urlVars = [String]()
        
        for (key, value) in parameters {
            
            /* Make sure that it is a string value */
            let stringValue = "\(value)"
            
            /* Escape it */
            let escapedValue = stringValue.stringByAddingPercentEncodingWithAllowedCharacters(NSCharacterSet.URLQueryAllowedCharacterSet())
            
            /* FIX: Replace spaces with '+' */
            let replaceSpaceValue = stringValue.stringByReplacingOccurrencesOfString(" ", withString: "+", options: NSStringCompareOptions.LiteralSearch, range: nil)
            
            /* Append it */
            urlVars += [key + "=" + "\(replaceSpaceValue)"]
        }
        
        return (!urlVars.isEmpty ? "?" : "") + join("&", urlVars)
    }
}


// Ref: http://stackoverflow.com/a/28191539/223228

public class SynchronizedArray<T> {
    private var array: [T] = []
    private let accessQueue = dispatch_queue_create("SynchronizedArrayAccess", DISPATCH_QUEUE_SERIAL)
    
    public func append(newElement: T) {
        dispatch_async(self.accessQueue) {
            self.array.append(newElement)
        }
    }
    
    public subscript(index: Int) -> T {
        set {
            dispatch_async(self.accessQueue) {
                self.array[index] = newValue
            }
        }
        get {
            var element: T!
            
            dispatch_sync(self.accessQueue) {
                element = self.array[index]
            }
            
            return element
        }
    }
    
    public var count: Int {
        var result: Int = 0
        dispatch_sync(self.accessQueue) {
            result = self.array.count
        }
        return result
    }
}


// MARK: - GCD util vars
// Ref: http://www.raywenderlich.com/79149/grand-central-dispatch-tutorial-swift-part-1

var GlobalMainQueue: dispatch_queue_t {
    return dispatch_get_main_queue()
}

var GlobalUserInteractiveQueue: dispatch_queue_t {
    return dispatch_get_global_queue(Int(QOS_CLASS_USER_INTERACTIVE.value), 0)
}

var GlobalUserInitiatedQueue: dispatch_queue_t {
    return dispatch_get_global_queue(Int(QOS_CLASS_USER_INITIATED.value), 0)
}

var GlobalUtilityQueue: dispatch_queue_t {
    return dispatch_get_global_queue(Int(QOS_CLASS_UTILITY.value), 0)
}

var GlobalBackgroundQueue: dispatch_queue_t {
    return dispatch_get_global_queue(Int(QOS_CLASS_BACKGROUND.value), 0)
}



