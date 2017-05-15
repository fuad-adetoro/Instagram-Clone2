//
//  AppDelegate.swift
//  Instagram Clone
//
//  Created by Fuad on 24/03/2017.
//  Copyright © 2017 FuadAdetoro. All rights reserved.
//

import UIKit
import Firebase

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

    var window: UIWindow?


    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplicationLaunchOptionsKey: Any]?) -> Bool {
        
        FIRApp.configure()
        
        logUser()
        
        return true
    }
    
    func logUser() {
        // Check if current user isn't nil, i.e. user exists.
        if FIRAuth.auth()?.currentUser != nil {
            let tabBar = UIStoryboard(name: "Main", bundle: nil).instantiateViewController(withIdentifier: "LoggedInMainTabBar") as! UITabBarController
            self.window?.rootViewController = tabBar
        }
        
    }

}

