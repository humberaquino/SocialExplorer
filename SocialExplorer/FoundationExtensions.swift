//
//  FoundationExtensions.swift
//  SocialExplorer
//
//  Created by Humberto Aquino on 5/5/15.
//  Copyright (c) 2015 Humberto Aquino. All rights reserved.
//

import Foundation

// Extending foundation objects can be considered a bad design practice.
// However I consider it very elegant practice if used carefully
// This file should be the only place where the Foundation objects are extended

extension NSObject {
    func performOnMainQueue(callback: () -> Void) {
        dispatch_async(dispatch_get_main_queue(), callback)
        return
    }    
}

extension Dictionary {
    mutating func merge<K, V>(dict: [K: V]){
        for (k, v) in dict {
            self.updateValue(v as! Value, forKey: k as! Key)
        }
    }
}


extension NSDate {
    func timestampIntervalInMilliseconsSince1970() -> Int {
        return Int(NSDate().timeIntervalSince1970 * 1000)
    }
}

extension NSOrderedSet {
    func cloneAndAddObject(object: AnyObject) -> NSOrderedSet {
        var mutableItems = self.mutableCopy() as! NSMutableOrderedSet
        mutableItems.addObject(object)
        return mutableItems.copy() as! NSOrderedSet
    }
}


