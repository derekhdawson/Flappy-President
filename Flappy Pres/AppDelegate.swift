//
//  AppDelegate.swift
//  Flappy President
//
//  Created by Derek Dawson on 8/1/16.
//  Copyright © 2016 Derek Dawson. All rights reserved.
//
//  App ID: ca-app-pub-5214892420848108~8919704073
//  Ad unit ID: ca-app-pub-5214892420848108/
//

import UIKit
import SpriteKit

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {
    
    var window: UIWindow?
    
    
    func application(application: UIApplication, didFinishLaunchingWithOptions launchOptions: [NSObject: AnyObject]?) -> Bool {
        // Override point for customization after application launch.
        
        let configuration = ParseClientConfiguration {
            $0.applicationId = "MZHYGCGgwNrVwxWx"
            $0.server = "https://flappy-president.herokuapp.com/parse"
        }
        
        Parse.initializeWithConfiguration(configuration)
        
        let uuid = UIDevice.currentDevice().identifierForVendor!.UUIDString
        let launchedBefore = NSUserDefaults.standardUserDefaults().stringForKey(uuid)
        if launchedBefore != uuid  {
            PFAnonymousUtils.logInWithBlock({ (user, error) in
                user?["uuid"] = uuid
                user?.saveEventually({ (success, error) in
                    if error == nil {
                        print("saved user")
                        NSUserDefaults.standardUserDefaults().setObject(uuid, forKey: uuid)
                    } else {
                        print(error)
                    }
                })
            })
        }
        return true
    }
    
    func applicationWillResignActive(application: UIApplication) {
        // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
        // Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
    }
    
    func applicationDidEnterBackground(application: UIApplication) {
        // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
        // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
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
    
    
}


public extension CGFloat {
    
    public static func random() -> CGFloat {
        return CGFloat(Float(arc4random()) / 0xFFFFFFFF)
    }
    
    public static func random(min min: CGFloat, max: CGFloat) -> CGFloat {
        return CGFloat.random() * (max - min) + min
    }
    
}

import AudioToolbox

extension SystemSoundID {
    static func playFileNamed(fileName: String, withExtenstion fileExtension: String? = "aif") {
        var sound: SystemSoundID = 0
        if let soundURL = NSBundle.mainBundle().URLForResource(fileName, withExtension: fileExtension) {
            AudioServicesCreateSystemSoundID(soundURL, &sound)
            AudioServicesPlaySystemSound(sound)
        }
    }
}

