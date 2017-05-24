//
//  UserActivity.swift
//  Instagram
//
//  Created by Fuad Adetoro on 22/05/2017.
//  Copyright © 2017 Instagram. All rights reserved.
//

import UIKit
import Firebase

enum ActivityType {
    case mentions
    case likes
    case followActivity
}

struct UserActivity {
    var timestamp: TimeInterval
    var userID: String
    var activityType: ActivityType
    var user: User?
    var postReference: Post?
    
    init(timestamp: TimeInterval, userID: String, activityType: ActivityType, postReference: Post?) {
        self.timestamp = timestamp
        self.userID = userID
        self.activityType = activityType
        self.postReference = postReference
    }
}
