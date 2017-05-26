//
//  SavedPosts.swift
//  Instagram
//
//  Created by apple  on 22/04/2017.
//  Copyright © 2017 Instagram. All rights reserved.
//

import Foundation
import Firebase

struct SavedPosts {
    var key: String!
    var userID: String!
    
    init(snapshot: DataSnapshot) {
        key = (snapshot.value as! NSDictionary)["key"] as! String
        userID = (snapshot.value as! NSDictionary)["userID"] as! String
    }
    
    init(key: String, userID: String) {
        self.key = key
        self.userID = userID
    }
}
