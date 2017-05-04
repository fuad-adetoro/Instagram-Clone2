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
class AppDelegate: UIResponder, UIApplicationDelegate, UITabBarControllerDelegate {

    var window: UIWindow?


    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplicationLaunchOptionsKey: Any]?) -> Bool {
        
        FIRApp.configure()
        
        logUser()
        
        self.window?.tintColor = UIColor.black
        
        return true
    }
    
    func tabBarController(_ tabBarController: UITabBarController, shouldSelect viewController: UIViewController) -> Bool {
        print("Tab selected")
        if viewController == tabBarController.viewControllers![2] {
            print("True")
            let storyboard = UIStoryboard(name: "Main", bundle: nil)
            let photoCollectionVC = storyboard.instantiateViewController(withIdentifier: "presentPhotoCol") as! UINavigationController
            tabBarController.present(photoCollectionVC, animated: true, completion: nil)
            return false
        }
        
        return true
    }
    
    func logUser() {
        // Check if current user isn't nil, i.e. user exists.
        let user = FIRAuth.auth()?.currentUser
        if user != nil {
            let tabBar = UIStoryboard(name: "Main", bundle: nil).instantiateViewController(withIdentifier: "LoggedInMainTabBar") as! UITabBarController
            self.window?.rootViewController = tabBar
        }
        
    }

}

