//
//  Likes.swift
//  Instagram Clone
//
//  Created by Fuad on 31/03/2017.
//  Copyright © 2017 FuadAdetoro. All rights reserved.
//

import UIKit
import Firebase

class Comments {
    var comment: String!
    var timestamp: TimeInterval!
    var userID: String!
    var key: String
    var ref: FIRDatabaseReference
    
    init(snapshot: FIRDataSnapshot) {
        key = snapshot.key
        ref = snapshot.ref
        comment = (snapshot.value as! NSDictionary)["comment"] as! String
        timestamp = (snapshot.value as! NSDictionary)["timestamp"] as! TimeInterval
        userID = (snapshot.value as! NSDictionary)["userID"] as! String
    }
}
