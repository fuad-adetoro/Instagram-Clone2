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
        let followersDict: [String: Any] = [currentUser.uid: true]
        let followingData = databaseRef.child("Users/\(currentUser.uid)/following/")
        let followersData = databaseRef.child("Users/\(userID)/followers/")
        
        followingData.updateChildValues(followDict)
        followersData.updateChildValues(followersDict)
        
    }
    
    func unFollowUser(userID: String, currentUser: FIRUser) {
        let followingData = databaseRef.child("Users/\(currentUser.uid)/following/\(userID)")
        let followersData = databaseRef.child("Users/\(userID)/followers/\(currentUser.uid)")
        
        followingData.removeValue()
        followersData.removeValue()
    }
    
    typealias FollowersFetched = ([User]) -> Void
    
    func fetchFollowing(user: User, completion: @escaping FollowersFetched) {
        let childData = databaseRef.child("Users/\(user.userID!)/following/")
        
        childData.observeSingleEvent(of: .value, with: { snapshot in
            if snapshot.exists() {
                let snapDict = snapshot.value as! [String: Any]
                let snapDictCount = snapDict.count
                var loopCount = 0
                var users: [User] = []
                for (userID, _) in snapDict {
                    let postService = PostService()
                    postService.userFromId(id: userID, completion: { (user) in
                        loopCount = loopCount + 1
                        users.append(user)
                        
                        if loopCount == snapDictCount {
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
            if snapshot.exists() {
                let snapDict = snapshot.value as! [String: Any]
                let snapDictCount = snapDict.count
                var loopCount = 0
                var users: [User] = []
                for (userID, _) in snapDict {
                    let postService = PostService()
                    postService.userFromId(id: userID, completion: { (user) in
                        loopCount = loopCount + 1
                        users.append(user)
                        
                        if loopCount == snapDictCount {
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
            for children in snapshot.children {
                let user = User(snapshot: children as! FIRDataSnapshot)
                
                
                if user.username! == username {
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
    
    
}
