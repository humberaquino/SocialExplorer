//
//  SettingsViewController.swift
//  SocialExplorer
//
//  Created by Humberto Aquino on 5/4/15.
//  Copyright (c) 2015 Humberto Aquino. All rights reserved.
//

import Foundation
import UIKit
import XCGLogger
import OAuthSwift
import SwiftOverlays

class SettingsViewController: UITableViewController {
    @IBOutlet weak var instagramSwitch: UISwitch!
    @IBOutlet weak var twitterSwitch: UISwitch!
    @IBOutlet weak var foursquareSwitch: UISwitch!
    @IBOutlet weak var facebookSwitch: UISwitch!
    
    @IBOutlet weak var instagramLabel: UILabel!
    @IBOutlet weak var twitterLabel: UILabel!
    @IBOutlet weak var foursquareLabel: UILabel!
    @IBOutlet weak var facebookLabel: UILabel!
    
    @IBOutlet weak var continueCell: UITableViewCell!
    
    var instagramToken: String!
    
    // MARK: - View life cycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        
        self.removeAllOverlays()
        
        let userSettings = UserSettings.sharedInstance()
        
        // Configure UI for Instagram
        if let instagramSettings =  userSettings.instagram.settings() {
            instagramSwitch.on = instagramSettings.active
            instagramToken = instagramSettings.token
        } else {
            // No instagram configured
            instagramSwitch.on = false
        }
        configureContinueCell()
    }
    
    
    // MARK: - Actions
    
    // TODO: This action has to be available only if settings appear after the help pages during the 
    // first time the app starts
    @IBAction func continueAction(sender: UIButton) {
        let tabBarController = self.navigationController?.parentViewController as! UITabBarController
        tabBarController.selectedIndex = 0
    }
    
    @IBAction func instagramSwitchChange(sender: UISwitch) {
        let userSettings = UserSettings.sharedInstance()
        if sender.on {
            // Enable instagram
            logger.debug("Enabling Instagram")
            if let instagramToken = userSettings.instagram.currentToken() {
                logger.debug("Instagram token already exits")
                self.instagramToken = instagramToken
                userSettings.instagram.activateService()
                configureContinueCell()
            } else {
                // Token does not exist
                logger.info("Starting Instagram authentication")
                startInstagramAuthentication()
            }
        } else {
            // Disable instagram
            logger.debug("Disabling Instagram")
            userSettings.instagram.disactivateService()
            configureContinueCell()
        }
    }
    
    @IBAction func twitterSwitchChange(sender: UISwitch) {
        
    }
    
    @IBAction func foursquareSwitchChange(sender: UISwitch) {
        
    }
    
    @IBAction func facebookSwitchChange(sender: UISwitch) {
        
    }
    
    
    // MARK: - Authentication
    
    // TODO: Move this to Authentication/Netowrking class
    func startInstagramAuthentication() {
        self.startAuthWithMessage("Authenticating", disablingSwitch:instagramSwitch)
        
        // Connect
        let oauthswift = OAuth2Swift(consumerKey: Config.Instagram.ClientId, consumerSecret: Config.Instagram.ClientSecret, authorizeUrl: Instagram.URL.Authorize, accessTokenUrl: Instagram.URL.AccessToken, responseType: Instagram.ParameteValues.Code)
        
        
        // FIXME
        let url = NSURL(string: "SocialExplorer://oauth-callback/instagram")!
        
        let userSettings = UserSettings.sharedInstance()
        
        let state: String = generateStateWithLength(20) as String
        oauthswift.authorizeWithCallbackURL(url, scope: "basic+likes", state: state,
            success: { (credential, response) -> Void in
                
                // Save token and and instagram enabled state
                self.instagramToken = credential.oauth_token
                userSettings.instagram.saveTokenAsCurrent(credential.oauth_token)
                
                // Complete the auth
                self.completeAuthAndEnableSwitch(self.instagramSwitch)
            },
            failure: { (error) -> Void in
                logger.error(error.localizedDescription)
                // Complete the auth
                self.completeAuthAndEnableSwitch(self.instagramSwitch)
        })
    }
    
    
    // MARK: - Utility methods
    
    func startAuthWithMessage(message: String, disablingSwitch aSwitch: UISwitch) {
        self.showWaitOverlayWithText(message)
        aSwitch.enabled = false
    }
    
    func completeAuthAndEnableSwitch(aSwitch: UISwitch) {
        self.removeAllOverlays()
        aSwitch.enabled = true
        configureContinueCell()
    }
    
    func configureContinueCell() {
        var hidden = true
        
        // TODO: Add the other tokens in the condition
        if instagramSwitch.on {
            hidden = false
        }
        
        continueCell.hidden = hidden
    }
    
}