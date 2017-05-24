//
//  AccountService.swift
//  Instagram
//
//  Created by apple  on 20/04/2017.
//  Copyright © 2017 Instagram. All rights reserved.
//

import UIKit
import Firebase

struct AccountService {
    
    typealias UserFetchComplete = (User) -> Void
    
    var databaseRef: FIRDatabaseReference {
        return FIRDatabase.database().reference()
    }
    
    func followUser(userID: String, currentUser: FIRUser) {
        let followDict: [String: Any] = [userID: true]
        let followTimestamp = Date().timeIntervalSince1970
        let followersDict: [String: Any] = ["userID": currentUser.uid, "timestamp": followTimestamp]
        let followingData = databaseRef.child("Users/\(currentUser.uid)/following/")
        let followersData = databaseRef.child("Users/\(userID)/followers/\(currentUser.uid)/")
        
        // This function adds the currentUser to the other users follers data and the user to be followed to the current user's following database
        
        followingData.updateChildValues(followDict)
        followersData.updateChildValues(followersDict)
        
    }
    
    func unFollowUser(userID: String, currentUser: FIRUser) {
        let followingData = databaseRef.child("Users/\(currentUser.uid)/following/\(userID)")
        let followersData = databaseRef.child("Users/\(userID)/followers/\(currentUser.uid)")
        
        // This function is the opposite of the followUser function and removes the userID from followers and following
        
        followingData.removeValue()
        followersData.removeValue()
    }
    
    typealias FollowersFetched = ([User]) -> Void
    
    func fetchFollowing(user: User, completion: @escaping FollowersFetched) {
        let childData = databaseRef.child("Users/\(user.userID!)/following/")
        
        childData.observeSingleEvent(of: .value, with: { snapshot in
            // Checking if data exists
            if snapshot.exists() {
                let snapDict = snapshot.value as! [String: Any]
                let snapDictCount = snapDict.count
                var loopCount = 0
                var users: [User] = []
                for (userID, _) in snapDict {
                    let postService = PostService()
                    // Fetching users using the userID from snapDict and appending it to the users array
                    postService.userFromId(id: userID, completion: { (user) in
                        loopCount = loopCount + 1
                        users.append(user)
                        
                        if loopCount == snapDictCount {
                            // Once loop is complete completion will be called.
                            completion(users)
                        }
                    })
                }
            }
        })
    }
    
    func fetchFollowers(user: User, completion: @escaping FollowersFetched) {
        let childData = databaseRef.child("Users/\(user.userID!)/followers/")
        
        childData.observeSingleEvent(of: .value, with: { snapshot in
            // Checking if data exists
            if snapshot.exists() {
                let snapDict = snapshot.value as! [String: Any]
                let snapDictCount = snapDict.count
                var loopCount = 0
                var users: [User] = []
                for (userID, _) in snapDict {
                    let postService = PostService()
                    // Fetching users using the userID from snapDict and appending it to the users array
                    postService.userFromId(id: userID, completion: { (user) in
                        loopCount = loopCount + 1
                        users.append(user)
                        
                        if loopCount == snapDictCount {
                            // Once loop is complete completion will be called.
                            completion(users)
                        }
                    })
                }
            }
        })
    }
    
    func fetchUserWithUsername(username: String, completion: @escaping UserFetchComplete) {
        let userData = databaseRef.child("Users/")
        
        userData.observeSingleEvent(of: .value, with: { snapshot in
            // Searching "Users/" which will have children if it's not empty
            for children in snapshot.children {
                // if children is found then we cast the child as a User
                let user = User(snapshot: children as! FIRDataSnapshot)
                
                if user.username! == username {
                    // If the username equals the username being passed to the function the completion will be called.
                    completion(user)
                }
            }
        })
    }
    
    func isFollowingUser(userID: String, currentUserID: String, completion: @escaping (Bool) -> Void) {
        let userData = FIRDatabase.database().reference(withPath: "Users/\(currentUserID)/following/\(userID)")
        
        userData.observeSingleEvent(of: .value, with: { snapshot in
            if snapshot.exists() {
                completion(true)
            } else {
                completion(false)
            }
        })
    }
    
    func searchUsers(searchText: String, completion: @escaping FollowersFetched) {
        let userData = databaseRef.child("Users/")
        var users: [User] = []
        
        userData.observeSingleEvent(of: .value, with: { snapshot in
            for child in snapshot.children {
                // if children is found then we cast the child as a User
                let user = User(snapshot: child as! FIRDataSnapshot)
                print("UserData: \(user.username!)")
                // lowercase the name as all usernames will be lowercased
                let lowercasedSearchText = searchText.lowercased()
                
                // If the found user's username name includes the searchText which was passed then append users
                if user.username!.contains(lowercasedSearchText) {
                    users.append(user)
                } else if let name = user.name, name.contains(lowercasedSearchText) {
                    users.append(user)
                }
            }
            
            print("Users: \(users)")
            
            completion(users)
        })
    }
    
}
