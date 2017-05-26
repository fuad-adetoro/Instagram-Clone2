//
//  Post.swift
//  Instagram Clone
//
//  Created by Fuad on 28/03/2017.
//  Copyright © 2017 FuadAdetoro. All rights reserved.
//

import Foundation
import Firebase

struct Post {    
    var imageURL: String!
    var timestamp: TimeInterval!
    var caption: String?
    var key: String
    var ref: DatabaseReference
    var likes: Int!
    var userID: String!
    var username: String!
    var hashtags: String?
    var mentions: String?
    var likers: [String: Any]?
    
    init(snapshot: DataSnapshot) {
        key = snapshot.key
        ref = snapshot.ref
        imageURL = (snapshot.value as! NSDictionary)["imageURL"] as! String
        timestamp = (snapshot.value as! NSDictionary)["timestamp"] as! TimeInterval
        caption = (snapshot.value! as! NSDictionary)["caption"] as? String
        likes = (snapshot.value as! NSDictionary)["likes"] as! Int
        userID = (snapshot.value as! NSDictionary)["userID"] as! String
        username = (snapshot.value as! NSDictionary)["username"] as! String
        hashtags = (snapshot.value as! NSDictionary)["hashtags"] as? String
        mentions = (snapshot.value as! NSDictionary)["mentions"] as? String
        likers = (snapshot.value as? NSDictionary)?["likers"] as? [String: [String: Any]]
        
        if likers != nil {
            print("ALLLIKERS: \(likers!)")
        }
    }
}
