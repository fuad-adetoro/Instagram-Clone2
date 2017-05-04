//
//  PostDateExtension.swift
//  Instagram Clone
//
//  Created by Fuad on 30/03/2017.
//  Copyright © 2017 FuadAdetoro. All rights reserved.
//

import UIKit

extension Date {
    func timeAgoDisplay() -> String {
        print("Date RIGHT NOW: \(self)")
        let secondsAgo = Int(Date().timeIntervalSince(self))
        print("Seconds ago \(secondsAgo)")
        
        if secondsAgo >= 86400 * 2 {
            return "\(((secondsAgo / 60) / 60) / 24) days ago"
        } else if secondsAgo >= 86400 {
            return "\(((secondsAgo / 60) / 60) / 24) day ago"
        } else if secondsAgo > 7200 {
            return "\((secondsAgo / 60) / 60) hours ago"
        } else if secondsAgo >= 3600 {
            return "\((secondsAgo / 60) / 60) Hour ago"
        } else if secondsAgo < 60 {
            return "\(secondsAgo) seconds ago"
        } else if secondsAgo > 119 {
            return "\(secondsAgo / 60) minutes ago"
        }
            
        return "\(secondsAgo / 60) minute ago"
    }
    
    func timeSinceComment() -> String {
        
        let secondsAgo = Int(Date().timeIntervalSince(self))
        
        if secondsAgo >= 86400 * 2 {
            return "\(((secondsAgo / 60) / 60) / 24)d"
        } else if secondsAgo >= 86400 {
            return "\(((secondsAgo / 60) / 60) / 24)d"
        } else if secondsAgo > 7200 {
            return "\((secondsAgo / 60) / 60)h"
        } else if secondsAgo >= 3600 {
            return "\((secondsAgo / 60) / 60)h"
        } else if secondsAgo < 60 {
            return "\(secondsAgo)s"
        } else if secondsAgo > 119 {
            return "\(secondsAgo / 60)m"
        }
        
        return "1h"
    }
}
