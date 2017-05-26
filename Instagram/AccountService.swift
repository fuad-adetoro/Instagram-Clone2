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
    
    typealias ProfileFetchComplete = (Profile) -> Void
    
    var databaseRef: DatabaseReference {
        return Database.database().reference()
    }
    
    func followUser(userID: String, currentUser: User) {
        let followDict: [String: Any] = [userID: true]
        let followTimestamp = Date().timeIntervalSince1970
        let followersDict: [String: Any] = ["userID": currentUser.uid, "timestamp": followTimestamp]
        let followingData = databaseRef.child("Users/\(currentUser.uid)/following/")
        let followersData = databaseRef.child("Users/\(userID)/followers/\(currentUser.uid)/")
        
        // This function adds the currentUser to the other users follers data and the user to be followed to the current user's following database
        
        followingData.updateChildValues(followDict)
        followersData.updateChildValues(followersDict)
        
    }
    
    func unFollowUser(userID: String, currentUser: User) {
        let followingData = databaseRef.child("Users/\(currentUser.uid)/following/\(userID)")
        let followersData = databaseRef.child("Users/\(userID)/followers/\(currentUser.uid)")
        
        // This function is the opposite of the followUser function and removes the userID from followers and following
        
        followingData.removeValue()
        followersData.removeValue()
    }
    
    typealias FollowersFetched = ([Profile]) -> Void
    
    func fetchFollowing(profile: Profile, completion: @escaping FollowersFetched) {
        let childData = databaseRef.child("Users/\(profile.userID!)/following/")
        
        childData.observeSingleEvent(of: .value, with: { snapshot in
            // Checking if data exists
            if snapshot.exists() {
                let snapDict = snapshot.value as! [String: Any]
                let snapDictCount = snapDict.count
                var loopCount = 0
                var profiles: [Profile] = []
                for (userID, _) in snapDict {
                    let postService = PostService()
                    // Fetching users using the userID from snapDict and appending it to the users array
                    postService.userFromId(id: userID, completion: { (profile) in
                        loopCount = loopCount + 1
                        profiles.append(profile)
                        
                        if loopCount == snapDictCount {
                            // Once loop is complete completion will be called.
                            completion(profiles)
                        }
                    })
                }
            }
        })
    }
    
    func fetchFollowers(profile: Profile, completion: @escaping FollowersFetched) {
        let childData = databaseRef.child("Users/\(profile.userID!)/followers/")
        
        childData.observeSingleEvent(of: .value, with: { snapshot in
            // Checking if data exists
            if snapshot.exists() {
                let snapDict = snapshot.value as! [String: Any]
                let snapDictCount = snapDict.count
                var loopCount = 0
                var profiles: [Profile] = []
                for (userID, _) in snapDict {
                    let postService = PostService()
                    // Fetching users using the userID from snapDict and appending it to the users array
                    postService.userFromId(id: userID, completion: { (user) in
                        loopCount = loopCount + 1
                        profiles.append(profile)
                        
                        if loopCount == snapDictCount {
                            // Once loop is complete completion will be called.
                            completion(profiles)
                        }
                    })
                }
            }
        })
    }
    
    func fetchUserWithUsername(username: String, completion: @escaping ProfileFetchComplete) {
        let userData = databaseRef.child("Users/")
        
        userData.observeSingleEvent(of: .value, with: { snapshot in
            // Searching "Users/" which will have children if it's not empty
            for children in snapshot.children {
                // if children is found then we cast the child as a User
                let profile = Profile(snapshot: children as! DataSnapshot)
                
                if profile.username! == username {
                    // If the username equals the username being passed to the function the completion will be called.
                    completion(profile)
                }
            }
        })
    }
    
    func isFollowingUser(userID: String, currentUserID: String, completion: @escaping (Bool) -> Void) {
        let userData = Database.database().reference(withPath: "Users/\(currentUserID)/following/\(userID)")
        
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
        var profiles: [Profile] = []
        
        userData.observeSingleEvent(of: .value, with: { snapshot in
            for child in snapshot.children {
                // if children is found then we cast the child as a User
                let profile = Profile(snapshot: child as! DataSnapshot)
                print("UserData: \(profile.username!)")
                // lowercase the name as all usernames will be lowercased
                let lowercasedSearchText = searchText.lowercased()
                
                // If the found user's username name includes the searchText which was passed then append users
                if profile.username!.contains(lowercasedSearchText) {
                    profiles.append(profile)
                } else if let name = profile.name, name.contains(lowercasedSearchText) {
                    profiles.append(profile)
                }
            }
                        
            completion(profiles)
        })
    }
    
}
