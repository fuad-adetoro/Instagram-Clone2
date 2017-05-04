//
//  UIButtonExtension.swift
//  Instagram Clone
//
//  Created by Fuad on 02/04/2017.
//  Copyright © 2017 FuadAdetoro. All rights reserved.
//

import UIKit

extension UIButton {
    func setupLoaderButton() {
        let activityIndicator = UIActivityIndicatorView()
        let loginButtonHeight = self.frame.size.height
        let loginButtonWidth = self.frame.size.width
        activityIndicator.center = CGPoint(x: loginButtonWidth/2, y: loginButtonHeight/2)
        activityIndicator.tag = 2017
        self.addSubview(activityIndicator)
        activityIndicator.startAnimating()
    }
}


