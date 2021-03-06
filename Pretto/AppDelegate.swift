//
//  AppDelegate.swift
//  Pretto
//
//  Created by Josiah Gaskin on 6/3/15.
//  Copyright (c) 2015 Pretto. All rights reserved.
//

import UIKit

let dateFormatter = NSDateFormatter()
let kUserDidLogOutNotification = "userDidLogOut"
let kShowLoginWindowNotification = "showLoginWindow"
let kShowLandingWindowNotification = "showLandingWindow"
let kIntroDidFinishNotification = "introIsOver"
let kShareOnFacebookNotification = "shareOnFacebook"
let kShareOnTwitterNotification = "shareOnTwitter"
let kShareByEmailNotification = "shareByEmail"
let kAcceptEventAndDismissVCNotification = "acceptEventAndDismissVC"
let kFirstTimeRunningPretto = "isTheFirstTimeEver"
let kDidPressCreateEventNotification = "createNewEvent"
let kUserDidPressCameraNotification = "openCamera"

let cameraView: UIImageView = UIImageView()

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate, PFLogInViewControllerDelegate, PFSignUpViewControllerDelegate {

    var window: UIWindow?
    private var isTheFirstTimeEver = false
    
    func application(application: UIApplication, didFinishLaunchingWithOptions launchOptions: [NSObject: AnyObject]?) -> Bool {
        println("didFinishLaunchingWithOptions")
        
        UIApplication.sharedApplication().setStatusBarStyle(UIStatusBarStyle.LightContent, animated: false)
        GlobalAppearance.setAll()
        
        registerDataModels()
        
        Parse.enableLocalDatastore()
        
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "showLoginWindow", name: kShowLoginWindowNotification, object: nil)
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "showLandingWindow", name: kShowLandingWindowNotification, object: nil)
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "introDidFinish", name: kIntroDidFinishNotification, object: nil)
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "userDidLogOut", name: kUserDidLogOutNotification, object: nil)
        
        
        // Initialize Parse.
        Parse.setApplicationId("EwtAHVSdrZseylxvkalCaMQ3aTWknFUgnhJRcozx",
            clientKey: "kA7v5dqEEndRpZgcOsL2G4jitdGuPzj63xmYm7xZ")
        
        PFFacebookUtils.initializeFacebookWithApplicationLaunchOptions(launchOptions)
        
        application.setMinimumBackgroundFetchInterval(60 * 60)
        
        // Register for Push Notitications
        self.registerForRemoteNotifications(application, launchOptions:launchOptions)
        
        // check user and start a storyboard accordingly
        let isFirstTime: Bool? = NSUserDefaults.standardUserDefaults().objectForKey(kFirstTimeRunningPretto) as? Bool
        
        if  isFirstTime == nil || isFirstTime == true {
            self.showIntroWindow()
        } else {
            self.checkCurrentUser()
        }
        return false
    }
    
    func registerForRemoteNotifications(application: UIApplication, launchOptions: [NSObject: AnyObject]?) {
        println("registerForRemoteNotifications")
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
        println("didRegisterForRemoteNotificationsWithDeviceToken")
        let installation = PFInstallation.currentInstallation()
        installation.setDeviceTokenFromData(deviceToken)
        installation.saveInBackgroundWithBlock(nil)
    }
    
    func application(application: UIApplication, didFailToRegisterForRemoteNotificationsWithError error: NSError) {
        println("didFailToRegisterForRemoteNotificationsWithError")
        if error.code == 3010 {
            println("Push notifications are not supported in the iOS Simulator.")
        } else {
            println("application:didFailToRegisterForRemoteNotificationsWithError: %@", error)
        }
    }
    
    func application(application: UIApplication, didReceiveRemoteNotification userInfo: [NSObject : AnyObject]) {
        println("didReceiveRemoteNotification")
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
            println("openURL")
            
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
        var currentInstallation = PFInstallation.currentInstallation()
        if (currentInstallation.badge != 0) {
            currentInstallation.badge = 0
            currentInstallation.saveEventually()
        }
    }

    func applicationWillTerminate(application: UIApplication) {
        
    }
    
}

//MARK: Auxiliary Functions

extension AppDelegate {
    
    func addCameraOverlay() {
        var window = UIApplication.sharedApplication().keyWindow
        let iconSize = CGSize(width: 56.0, height: 56.0)
        let margin = CGFloat(8.0)
        window?.addSubview(cameraView)
        window?.bringSubviewToFront(cameraView)
        cameraView.frame = CGRect(origin: CGPoint(x: 0, y: 0), size: iconSize)
        cameraView.backgroundColor = UIColor.clearColor()
        cameraView.image = UIImage(named: "OverlayCameraButtonOrange")
        cameraView.center = CGPoint(x: window!.bounds.width - (iconSize.width / 2) - margin, y: window!.bounds.height - (iconSize.height / 2) - margin - 51)
        cameraView.userInteractionEnabled = true
        var tapRecognizer = UITapGestureRecognizer(target: self, action: "tappedOnCamera")
        cameraView.addGestureRecognizer(tapRecognizer)
    }
    
    func tappedOnCamera() {
        NSNotificationCenter.defaultCenter().postNotification(NSNotification(name: kUserDidPressCameraNotification, object: nil))
    }
    
    func checkCurrentUser() {
        println("AppDelegate: checkCurrentUser")
        User.checkCurrentUser({ (user:User) -> Void in
            println("Saving user details...")
            user.save()
            user.printProperties()
            self.startMainStoryBoard()
            self.fetchFriends(user)
            },
            otherwise: { (pfUser:PFUser?) -> Void in
                if pfUser != nil {
                    println("Unlinking user from FB")
                    PFFacebookUtils.unlinkUserInBackground(pfUser!)
                }
                self.showLandingWindow()
        })
    }
    
    func fetchFriends(user:User) {
        Friend.getAllFriendsFromFacebook(user.facebookId!, onComplete: { (friends:[Friend]?) -> Void in
            if friends != nil {
                println("Friends retrieved from FB")
                Friend.printDebugAll(friends!)
                Friend.getAllFriendsFromDBase(user.facebookId!, onComplete: { (savedFriends:[Friend]?) -> Void in
                    if savedFriends != nil {
                        var unsavedFriends = Friend.subtract(friends!, from: savedFriends!)
                        if unsavedFriends.count > 0 {
                            Friend.saveAllInBackground(unsavedFriends)
                            println("Saving friends invoked for \(unsavedFriends.count)")
                        } else {
                            println("Friends are up to date.")
                        }
                    } else {
                        println("No friends are saved yet. Attempting to save all.")
                        Friend.saveAllInBackground(friends!)
                        println("Saving friends invoked for \(friends!.count)")
                    }
                })
            } else {
                println("No FB friends using this app")
            }
        })
    }
    
    func userDidLogOut() {
        PFUser.logOut()
        (UIApplication.sharedApplication().delegate as! AppDelegate).showLandingWindow()
    }
    
    func introDidFinish() {
        println("introDidFinish")
        self.checkCurrentUser()
    }
    
    func showIntroWindow() {
        println("showIntroWindow")
        var introViewController = UIStoryboard(name: "Main", bundle: nil).instantiateViewControllerWithIdentifier("IntroViewController") as! IntroViewController
        self.window = UIWindow(frame: UIScreen.mainScreen().bounds)
        self.window!.rootViewController = introViewController
        self.window!.makeKeyAndVisible()
    }
    
    func showLandingWindow() {
        println("Show Landing Notification Received")
        var landingViewController = CustomLandingViewController()
        landingViewController.fields = .Facebook | .SignUpButton
        landingViewController.delegate = self
        self.window = UIWindow(frame: UIScreen.mainScreen().bounds)
        self.window!.rootViewController = landingViewController
        self.window!.makeKeyAndVisible()
    }
    
    func showLoginWindow() {
        println("Show Login Notification Received")
        var logInViewController = CustomLoginViewController()
        logInViewController.fields = .Facebook | .UsernameAndPassword | .PasswordForgotten | .LogInButton | .DismissButton
        logInViewController.delegate = self
        logInViewController.emailAsUsername = true
        self.window = UIWindow(frame: UIScreen.mainScreen().bounds)
        self.window!.rootViewController = logInViewController
        self.window!.makeKeyAndVisible()
    }
    
    func startMainStoryBoard() {
        println("startMainStoryBoard")
        self.window = UIWindow(frame:UIScreen.mainScreen().bounds)
        var mainSB = UIStoryboard(name: "Main", bundle: nil)
        let viewController = mainSB.instantiateInitialViewController() as! UITabBarController
        viewController.selectedIndex = 1
        self.window!.rootViewController = viewController
        self.window!.makeKeyAndVisible()
        self.addCameraOverlay()
    }
}

//MARK: PFSignUpViewControllerDelegate {

extension AppDelegate: PFSignUpViewControllerDelegate {
    
    func signUpViewController(signUpController: PFSignUpViewController, didSignUpUser user: PFUser) {
        println("Sign Up is Done")
        signUpController.dismissViewControllerAnimated(true, completion: nil)
        self.startMainStoryBoard()
    }
    func signUpViewControllerDidCancelSignUp(signUpController: PFSignUpViewController) {
        println("User did cancel Sign Up")
    }
    
    func signUpViewController(signUpController: PFSignUpViewController, didFailToSignUpWithError error: NSError?) {
        println("Error while signing up new user. Error: \(error)")
    }
}

//MARK: PFLogInViewControllerDelegate {

extension AppDelegate: PFLogInViewControllerDelegate {
    
    func logInViewController(logInController: PFLogInViewController, didLogInUser user: PFUser) {
        println("FB login is done")
       
        // Handles the very first time a user logs in
        let isFirstTime: Bool? = NSUserDefaults.standardUserDefaults().objectForKey(kFirstTimeRunningPretto) as? Bool
        
        if  isFirstTime == nil || isFirstTime == true {
            NSUserDefaults.standardUserDefaults().setBool(false, forKey: kFirstTimeRunningPretto)
            logInController.dismissViewControllerAnimated(true, completion: nil)
            self.checkCurrentUser()
        } else {
            logInController.dismissViewControllerAnimated(true, completion: nil)
            self.startMainStoryBoard()
        }
    }
    
    func logInViewControllerDidCancelLogIn(logInController: PFLogInViewController) {
        println("User did cancel Sign Up")
    }
    
    func logInViewController(logInController: PFLogInViewController, didFailToLogInWithError error: NSError?) {
        println("Error while loging in new user. Error: \(error)")
    }
}
