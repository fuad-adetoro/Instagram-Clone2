//
//  CustomTabBarController.swift
//  Instagram Clone
//
//  Created by Fuad on 27/03/2017.
//  Copyright © 2017 FuadAdetoro. All rights reserved.
//

import UIKit
import Firebase

class CustomTabBarController: UITabBarController {

    var user: FIRUser!
    
    override func viewDidLoad() {
        super.viewDidLoad()

        let profileVC = ProfilePageViewController()
        profileVC.tabBarItem.image = #imageLiteral(resourceName: "profiletab")
        //profileVC.user = user
        
        viewControllers = [profileVC]
    }
    
    override func viewWillLayoutSubviews() {
        var tabFrame = self.tabBar.frame
        
        
        tabFrame.size.height = 40
        tabFrame.origin.y = self.view.frame.size.height - 40
        self.tabBar.frame = tabFrame
    }
    
    
}
