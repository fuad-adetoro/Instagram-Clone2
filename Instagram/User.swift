//
//  User.swift
//  Instagram Clone
//
//  Created by Fuad on 26/03/2017.
//  Copyright © 2017 FuadAdetoro. All rights reserved.
//

import UIKit
import Firebase

struct User {
    var username: String!
    var email: String!
    var name: String?
    var photoURL: String?
    var biograph: String?
    var phoneNumber: String?
    var phoneNumberEmail: Bool?
    var website: String?
    var gender: String?
    var userID: String!
    var following: [String: Any]?
    var followers: [String: Any]?
    
    var databaseRef: FIRDatabaseReference {
        return FIRDatabase.database().reference()
    }
    
    init(snapshot: FIRDataSnapshot) {
        username = (snapshot.value! as! NSDictionary)["username"] as! String
        email = (snapshot.value! as! NSDictionary)["email"] as! String
        name = (snapshot.value! as! NSDictionary)["fullName"] as? String
        photoURL = (snapshot.value! as! NSDictionary)["photoURL"] as? String
        biograph = (snapshot.value! as! NSDictionary)["biograph"] as? String
        phoneNumber = (snapshot.value as! NSDictionary)["phoneNumber"] as? String
        phoneNumberEmail = (snapshot.value as! NSDictionary)["phoneNumberEmail"] as? Bool
        website = (snapshot.value as! NSDictionary)["website"] as? String
        gender = (snapshot.value as! NSDictionary)["gender"] as? String
        userID = (snapshot.value as! NSDictionary)["userID"] as! String
        following = (snapshot.value as? NSDictionary)?["following"] as? [String: Any]
        followers = (snapshot.value as? NSDictionary)?["followers"] as? [String: Any]
    }
}



