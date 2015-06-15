//
//  AppDelegate.swift
//  Pretto
//
//  Created by Josiah Gaskin on 6/3/15.
//  Copyright (c) 2015 Pretto. All rights reserved.
//

import UIKit

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate, PFLogInViewControllerDelegate {

    var window: UIWindow?


    func application(application: UIApplication, didFinishLaunchingWithOptions launchOptions: [NSObject: AnyObject]?) -> Bool {
        Parse.enableLocalDatastore()
        
        // Initialize Parse.
        Parse.setApplicationId("EwtAHVSdrZseylxvkalCaMQ3aTWknFUgnhJRcozx",
            clientKey: "kA7v5dqEEndRpZgcOsL2G4jitdGuPzj63xmYm7xZ")
        
        PFFacebookUtils.initializeFacebookWithApplicationLaunchOptions(launchOptions)
        
        application.setMinimumBackgroundFetchInterval(60 * 60)
        
        // Register for Push Notitications
        self.registerForRemoteNotifications(application, launchOptions:launchOptions)
        
        // check user and start a storyboard accourdingly
        self.checkCurrentUser({ (user:User) -> Void in
                user.save()
                println(user.facebookId)
                println(user.email)
                println(user.name)
                println(user.profilePhotoUrl)
                self.startMainStoryBoard()
            },
            otherwise: { (pfUser:PFUser?) -> Void in
                if pfUser != nil {
                    PFFacebookUtils.unlinkUserInBackground(pfUser!)
                }
                self.showLoginWindow()
            })
        
        return false
    }
    
    func checkCurrentUser(onValidUser:((User)->Void), otherwise:((PFUser?)->Void)) {
        var currentUser = PFUser.currentUser()
        if currentUser != nil {
            if PFFacebookUtils.isLinkedWithUser(currentUser!) {
                var request = FBSDKGraphRequest(graphPath: "me", parameters: nil)
                request.startWithCompletionHandler { (conn:FBSDKGraphRequestConnection!, res:AnyObject!, err:NSError!) -> Void in
                    if err == nil && res != nil {
                        var userData = res as! NSDictionary
                        var facebookId = userData["id"] as! String
                        var name = userData["name"] as! String
                        var email = userData["email"] as! String?
                        
                        var currentUser = PFUser.currentUser()
                        var user = User(innerUser: currentUser)
                        user.facebookId = facebookId
                        user.email = email
                        user.name = name
                        
                        onValidUser(user)
                    }
                    else {
                        otherwise(PFUser.currentUser())
                    }
                }

            } else {
                otherwise(nil)
            }
        } else {
            otherwise(nil)
        }
    }
    
    func logInViewController(logInController: PFLogInViewController, didLogInUser user: PFUser) {
        println("FB login is done")
        self.startMainStoryBoard()
    }
    
    func registerForRemoteNotifications(application: UIApplication, launchOptions: [NSObject: AnyObject]?) {
        
        if application.applicationState != UIApplicationState.Background {
            // Track an app open here if we launch with a push, unless
            // "content_available" was used to trigger a background push (introduced in iOS 7).
            // In that case, we skip tracking here to avoid double counting the app-open.
            
            let preBackgroundPush = !application.respondsToSelector("backgroundRefreshStatus")
            let oldPushHandlerOnly = !self.respondsToSelector("application:didReceiveRemoteNotification:fetchCompletionHandler:")
            var pushPayload = false
            if let options = launchOptions {
                pushPayload = options[UIApplicationLaunchOptionsRemoteNotificationKey] != nil
            }
            if (preBackgroundPush || oldPushHandlerOnly || pushPayload) {
                PFAnalytics.trackAppOpenedWithLaunchOptionsInBackground(launchOptions, block: nil)
                
            }
        }
        
        if application.respondsToSelector("registerUserNotificationSettings:") {
            let userNotificationTypes = UIUserNotificationType.Alert | UIUserNotificationType.Badge | UIUserNotificationType.Sound
            let settings = UIUserNotificationSettings(forTypes: userNotificationTypes, categories: nil)
            application.registerUserNotificationSettings(settings)
            application.registerForRemoteNotifications()
        } else {
            application.registerForRemoteNotifications()
        }
    }
    
    func application(application: UIApplication, didRegisterForRemoteNotificationsWithDeviceToken deviceToken: NSData) {
        let installation = PFInstallation.currentInstallation()
        installation.setDeviceTokenFromData(deviceToken)
        installation.saveInBackgroundWithBlock(nil)
    }
    
    func application(application: UIApplication, didFailToRegisterForRemoteNotificationsWithError error: NSError) {
        if error.code == 3010 {
            println("Push notifications are not supported in the iOS Simulator.")
        } else {
            println("application:didFailToRegisterForRemoteNotificationsWithError: %@", error)
        }
    }
    
    func application(application: UIApplication, didReceiveRemoteNotification userInfo: [NSObject : AnyObject]) {
        PFPush.handlePush(userInfo)
        if application.applicationState == UIApplicationState.Inactive {
            PFAnalytics.trackAppOpenedWithRemoteNotificationPayloadInBackground(userInfo, block: nil)
        }
        println("Remote Notification Received!")
    }
    
    func application(application: UIApplication,
        openURL url: NSURL,
        sourceApplication: String?,
        annotation: AnyObject?) -> Bool {
            
            return FBSDKApplicationDelegate.sharedInstance().application(
                application,
                openURL: url,
                sourceApplication: sourceApplication,
                annotation: annotation)
    }
    
    func application(application: UIApplication, performFetchWithCompletionHandler completionHandler: (UIBackgroundFetchResult) -> Void) {
        // TODO - upload new pictures here
    }

    func applicationWillResignActive(application: UIApplication) {
        
    }

    func applicationDidEnterBackground(application: UIApplication) {
        
    }

    func applicationWillEnterForeground(application: UIApplication) {
        
    }

    func applicationDidBecomeActive(application: UIApplication) {
        FBSDKAppEvents.activateApp()
    }

    func applicationWillTerminate(application: UIApplication) {
        
    }
    
    func showLoginWindow() {
        var logInController = LoginViewController()
        logInController.fields = .Facebook
        logInController.delegate = self;
        self.window?.rootViewController = logInController
    }
    
    func startMainStoryBoard() {
        self.startStoryBoardWithName("Main")
    }
    
    func startStoryBoardWithName(name:String!) {
        var loginSB = UIStoryboard(name: name, bundle: nil)
        let viewcontroller: UIViewController = loginSB.instantiateInitialViewController() as! UIViewController
        self.window!.rootViewController = viewcontroller
    }
}

