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

// View used to enable or disable the social networks to use
class SettingsViewController: UITableViewController {
    
    
    let ShowMainViewId = "ShowMainView"
    
    @IBOutlet weak var instagramSwitch: UISwitch!
    @IBOutlet weak var foursquareSwitch: UISwitch!
    @IBOutlet weak var instagramLabel: UILabel!
    @IBOutlet weak var foursquareLabel: UILabel!
    @IBOutlet weak var continueCell: UITableViewCell!
    
    var instagramToken: String!
    
    let userSettings = UserSettings.sharedInstance()
    
    
    // MARK: - View life cycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        
        // Configure UI for Instagram
        self.configureInstagram()
        self.configureFoursquare()
        
        configureContinueCell()
    }
    
    
    func configureInstagram() {
        if let instagramSettings =  userSettings.instagram.settings() {
            instagramSwitch.on = instagramSettings.active
            instagramToken = instagramSettings.token
        } else {
            // No instagram configured
            instagramSwitch.on = false
        }
    }
    func configureFoursquare() {
        foursquareSwitch.on =  userSettings.foursquare.isServiceActive()
    }
    
    // MARK: - Actions
    
    @IBAction func continueAction(sender: UIButton) {
        performSegueWithIdentifier(ShowMainViewId, sender: self)
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
                // Disable now and let the oauth enable it
                sender.on = false
                startInstagramAuthentication()
            }
        } else {
            // Disable instagram
            logger.debug("Disabling Instagram")
            userSettings.instagram.disactivateService()
            configureContinueCell()
        }
    }
    
    @IBAction func foursquareSwitchChange(sender: UISwitch) {
        let userSettings = UserSettings.sharedInstance()
        if sender.on {
            logger.debug("Enabling Foursquare")
            userSettings.foursquare.activateService()
        } else {
            logger.debug("Disabling Foursquare")
            userSettings.foursquare.disactivateService()
        }
        configureContinueCell()      
    }
    
    // MARK: - Utility methods
    
    func completeAuthAndEnableSwitch(aSwitch: UISwitch) {
        aSwitch.on = true
        configureContinueCell()
    }
    
    func configureContinueCell() {
        
        var hidden = true
    
        if instagramSwitch.on || foursquareSwitch.on{
            hidden = false
        }
        if continueCell != nil {
            continueCell.hidden = hidden
        }
    }
    
}


 // MARK: - Authentication

extension SettingsViewController {
   
    func startInstagramAuthentication() {
    
        
        // Connect
        let oauthswift = OAuth2Swift(consumerKey: Config.Instagram.ClientId, consumerSecret: Config.Instagram.ClientSecret, authorizeUrl: InstagramOAuth.URL.Authorize, accessTokenUrl: InstagramOAuth.URL.AccessToken, responseType: InstagramOAuth.ParameteValues.Code)
        
        
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
}
