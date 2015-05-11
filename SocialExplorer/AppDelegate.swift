//
//  AppDelegate.swift
//  SocialExplorer
//
//  Created by Humberto Aquino on 5/3/15.
//  Copyright (c) 2015 Humberto Aquino. All rights reserved.
//

import UIKit
import OAuthSwift
import XCGLogger

// Global logger
let logger = XCGLogger.defaultInstance()

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

    var window: UIWindow?

    
    func application(application: UIApplication, didFinishLaunchingWithOptions launchOptions: [NSObject: AnyObject]?) -> Bool {

        self.setupLogging()
       
        
        logger.info("Application started")
        
        return true
    }

    func applicationWillResignActive(application: UIApplication) {
        // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
        // Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
    }

    func applicationDidEnterBackground(application: UIApplication) {
        // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
        // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
        NSUserDefaults.standardUserDefaults().synchronize()
    }

    func applicationWillEnterForeground(application: UIApplication) {
        // Called as part of the transition from the background to the inactive state; here you can undo many of the changes made on entering the background.
    }

    func applicationDidBecomeActive(application: UIApplication) {
        // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
    }

    func applicationWillTerminate(application: UIApplication) {
        // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
    }

    func application(application: UIApplication, openURL url: NSURL, sourceApplication: String?, annotation: AnyObject?) -> Bool {
        if url.host == "oauth-callback" {
            if url.path!.hasPrefix("/instagram") {
                OAuth2Swift.handleOpenURL(url)
            }
        }
        return true
    }
    
    private func setupLogging() {        
        logger.setup(logLevel: Config.Logger.LogLevel, showLogLevel: Config.Logger.ShowLogLevel, showFileNames: Config.Logger.ShowFileNames, showLineNumbers: Config.Logger.ShowLineNumbers, writeToFile: Config.Logger.WriteToFile, fileLogLevel: Config.Logger.FileLogLevel)
        
        var dateFormatter = NSDateFormatter()
        dateFormatter.dateFormat = "hh:mm:ss:SSS"
        dateFormatter.locale = NSLocale.currentLocale()
        logger.dateFormatter = dateFormatter
    }
 
}

