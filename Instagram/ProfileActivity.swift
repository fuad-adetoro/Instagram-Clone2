//
//  ProfileActivity.swift
//  Instagram
//
//  Created by Fuad Adetoro on 22/05/2017.
//  Copyright © 2017 Instagram. All rights reserved.
//

import UIKit
import Firebase

struct ProfileActivity {
    let profile: Profile
    let postService = PostService()
    let authService = AuthService()
    
    var databaseRef: DatabaseReference {
        return Database.database().reference()
    }
    
    init(profile: Profile) {
        self.profile = profile
    }

    func checkProfileActivity(completion: @escaping ([UserActivity]) -> Void) {
        searchPostsForMentions(completion: completion)
    }
    
    func attachUserToActivity(activity: [UserActivity], completion: @escaping ([UserActivity]) -> Void) {
        var userActivity: [UserActivity] = []
        let activityCount = activity.count
        var loopCount = 0
        
        for userProfileActivity in activity {
            let userID = userProfileActivity.userID
            authService.userFromId(id: userID, completion: { (profile) in
                loopCount = loopCount + 1
                var newActivity: UserActivity = userProfileActivity
                newActivity.profile = profile
                userActivity.append(newActivity)
                
                if loopCount == activityCount {
                    print("All Activities: \(userActivity)")
                    completion(userActivity)
                }
            })
        }
    }
    
    func searchPostLikers(activity: [UserActivity], completion: @escaping ([UserActivity]) -> Void) {
        var userActivity: [UserActivity] = activity
        print("Activity: \(userActivity)")
        
        postService.fetchPosts(userID: profile.userID!) { (posts) in
            for post in posts {
                if let likersDict = post.likers {
                    for (_, dict) in likersDict {
                        if let newLikersDict = dict as? [String: Any], let userID = newLikersDict["userID"] as? String, let timestamp = newLikersDict["timestamp"] as? TimeInterval {
                            // make sure we don't return notification for a user liking their own post
                            if userID != self.profile.userID! {
                                let usersActivity = UserActivity(timestamp: timestamp, userID: userID, activityType: .likes, postReference: post)
                                userActivity.append(usersActivity)
                            }
                        }
                    }
                }
            }
            
            self.attachUserToActivity(activity: userActivity, completion: completion)
        }
    }
    
    func searchFollowersActivity(activity: [UserActivity], completion: @escaping ([UserActivity]) -> Void) {
        let userData = databaseRef.child("Users/\(profile.userID!)/followers/")
        var userActivity: [UserActivity] = activity
        
        userData.observeSingleEvent(of: .value, with: { snapshot in
            for children in snapshot.children {
                let childSnapshot = children as! DataSnapshot
                let childSnapDict = childSnapshot.value as! NSDictionary
                if let timestamp = childSnapDict["timestamp"] as? TimeInterval, let userID = childSnapDict["userID"] as? String {
                    let usersActivity = UserActivity(timestamp: timestamp, userID: userID, activityType: .followActivity, postReference: nil)
                    userActivity.append(usersActivity)
                }
            }
            
            self.searchPostLikers(activity: userActivity, completion: completion)
        })
    }
    
    func searchPostsForMentions(completion: @escaping ([UserActivity]) -> Void) {
        let postData = databaseRef.child("Posts/")
        var userActivity: [UserActivity] = []
        let username = profile.username!
        
        postData.observeSingleEvent(of: .value, with: { snapshot in
            let childLoopCount = Int(snapshot.childrenCount)
            var loopCount = 0
            
            for child in snapshot.children {
                loopCount = loopCount + 1
                let snap = child as! DataSnapshot
                
                for children in snap.children {
                    let childSnap = children as! DataSnapshot
                    let childSnapDict = childSnap.value as! NSDictionary
                    if childSnapDict["userID"] != nil {
                        let post = Post(snapshot: childSnap)
                        
                        if let mentions = post.mentions {
                            for usernames in mentions.components(separatedBy: " ") {
                                if usernames == "@\(username)", post.userID! != self.profile.userID! {
                                    let usersActivity = UserActivity(timestamp: post.timestamp!, userID: post.userID!, activityType: .mentions, postReference: post)
                                    userActivity.append(usersActivity)
                                }
                            }
                        }
                    }
                }
                
                if loopCount == childLoopCount {
                    self.searchFollowersActivity(activity: userActivity, completion: completion)
                }
            }
        })
    }
}



