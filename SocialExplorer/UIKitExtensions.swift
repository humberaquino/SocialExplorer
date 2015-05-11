//
//  UIKitExtensions.swift
//  SocialExplorer
//
//  Created by Humberto Aquino on 5/5/15.
//  Copyright (c) 2015 Humberto Aquino. All rights reserved.
//

import Foundation
import UIKit


// Extending UIKit objects can be considered a bad design practice.
// However I consider it very elegant practice if used carefully
// This file should be the only place where the UIKit objects are extended

extension UIViewController {
    func showMessageWithTitle(title: String, message: String) {
        var alert = UIAlertController(title: title, message: message, preferredStyle: UIAlertControllerStyle.Alert)
        alert.addAction(UIAlertAction(title: "Ok", style: UIAlertActionStyle.Default, handler: nil))
        self.presentViewController(alert, animated: true, completion: nil)
    }
    
    func showConfirmation(message: String, resolutionHandler: ((confirmed: Bool) -> Void)) {
        var alert = UIAlertController(title: nil, message: message, preferredStyle: UIAlertControllerStyle.Alert)
        alert.addAction(UIAlertAction(title: "Cancel", style: UIAlertActionStyle.Cancel, handler: { (uiAlertAction) -> Void in
            resolutionHandler(confirmed: false)
        }))
        alert.addAction(UIAlertAction(title: "Override", style: UIAlertActionStyle.Default, handler: { (uiAlertAction) -> Void in
            resolutionHandler(confirmed: true)
        }))
        
        self.presentViewController(alert, animated: true, completion: nil)
    }
    
}