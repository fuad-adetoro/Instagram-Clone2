//
//  PostService.swift
//  Instagram Clone
//
//  Created by Fuad on 28/03/2017.
//  Copyright © 2017 FuadAdetoro. All rights reserved.
//

import UIKit
import Firebase

struct PostService {
    var databaseRef: DatabaseReference {
        return Database.database().reference()
    }
    
    var storageRef: StorageReference {
        return Storage.storage().reference()
    }
    
    typealias PostUploaded = (Bool) -> Void
    
    func createPost(picture: UIImage, caption: String, user: User, completion: @escaping PostUploaded) {
        var noCaption = true
        var hashtags: [String] = []
        var mentions: [String] = []
        
        if !caption.isEmpty {
            noCaption = false
            
            let words = caption.components(separatedBy: " ")
            
            for word in words {
                if word.hasPrefix("#") {
                    hashtags.append(word)
                } else if word.hasPrefix("@") {
                    mentions.append(word)
                }
            }
        }
        
        let data = UIImageJPEGRepresentation(picture, 5 * 1024 * 1024)! as NSData
        
        let postTimestamp = Date().timeIntervalSince1970
        
        let randomKey = databaseRef.child("Users/").childByAutoId().key
        
        let imageRef = storageRef.child("Posts/\(user.uid)/\(randomKey)")

        let metaData = StorageMetadata()
        metaData.contentType = "image/jpeg"
        
        imageRef.putData(data as Data, metadata: metaData) { (newMetaData, error) in
            if error == nil {
                let photoURL = newMetaData!.downloadURL()
                self.userFromId(id: user.uid, completion: { (profile) in
                    self.createPostInDatabase(noCaption: noCaption, caption: caption, imageURL: String(describing: photoURL!), profile: profile, key: randomKey, timestamp: postTimestamp, hashtags: hashtags, mentions: mentions)
                    completion(true)
                })
            } else {
                print(error?.localizedDescription)
                completion(false)
            }
        }
    }
    
    func createPostInDatabase(noCaption: Bool, caption: String, imageURL: String, profile: Profile, key: String, timestamp: TimeInterval, hashtags: [String], mentions: [String]) {
        let dictToUpload: [String: Any]
        
        print("timestamp: \(timestamp)")  
        
        if !noCaption {
            if hashtags != [] && mentions != [] {
                let hashtagString = hashtags.joined(separator: " ")
                let mentionString = mentions.joined(separator: " ")
                dictToUpload = ["caption": caption, "imageURL": imageURL, "timestamp": timestamp, "likes": 0, "userID": profile.userID!, "username": profile.username!, "hashtags": hashtagString, "mentions": mentionString]
            } else if hashtags != [] {
                let hashtagString = hashtags.joined(separator: " ")
                dictToUpload = ["caption": caption, "imageURL": imageURL, "timestamp": timestamp, "likes": 0, "userID": profile.userID!, "username": profile.username!, "hashtags": hashtagString]
            } else if mentions != [] {
                let mentionString = mentions.joined(separator: " ")
                dictToUpload = ["caption": caption, "imageURL": imageURL, "timestamp": timestamp, "likes": 0, "userID": profile.userID!, "username": profile.username!, "mentions": mentionString]
            } else {
                dictToUpload = ["caption": caption, "imageURL": imageURL, "timestamp": timestamp, "likes": 0, "userID": profile.userID!, "username": profile.username!]
            }
        } else {
            dictToUpload = ["imageURL": imageURL, "timestamp": timestamp, "likes": 0, "userID": profile.userID!, "username": profile.username!]
        }
        
        print("DICT \(dictToUpload)")
        
        let userData = databaseRef.child("Posts/\(profile.userID!)/\(key)")
        
        userData.setValue(dictToUpload) { (error, reference) in
            if let error = error as? NSError {
                print(error.localizedDescription)
            } else {
                print(reference)
            }
        }
    }
    
    typealias PostsReceived = ([Post]) -> Void
    
    func fetchPosts(user: User, completion: @escaping PostsReceived) {
        let postData = databaseRef.child("Posts/\(user.uid)/")
        
        postData.observeSingleEvent(of: .value, with: { (snapshot) in
            var posts: [Post] = []
            for children in snapshot.children {
                let childSnap = children as! DataSnapshot
                let childSnapDict = childSnap.value as! NSDictionary
                if childSnapDict["userID"] != nil {
                    let post = Post(snapshot: children as! DataSnapshot)
                    posts.append(post)
                }
            }
            completion(posts)
        })
    }
    
    func fetchPosts(userID: String, completion: @escaping PostsReceived) {
        let postData = databaseRef.child("Posts/\(userID)/")
        
        postData.observeSingleEvent(of: .value, with: { (snapshot) in
            var posts: [Post] = []
            for children in snapshot.children {
                let childSnap = children as! DataSnapshot
                let childSnapDict = childSnap.value as! NSDictionary
                if childSnapDict["userID"] != nil {
                    let post = Post(snapshot: children as! DataSnapshot)
                    posts.append(post)
                }
            }
            completion(posts)
        })
    }
    
    func fetchPosts(string: String, completion: @escaping PostsReceived) {
        let postData = databaseRef.child("Posts/")
        var posts: [Post] = []
        
        postData.queryOrdered(byChild: "timestamp").observeSingleEvent(of: .value, with: { snapshot in
            for child in snapshot.children {
                let snap = child as! DataSnapshot
                
                for children in snap.children {
                    print("User Child: \(children)")
                    let childSnap = children as! DataSnapshot
                    let childSnapDict = childSnap.value as! NSDictionary
                    if childSnapDict["userID"] != nil {
                        let post = Post(snapshot: children as! DataSnapshot)
                        posts.append(post)
                    }
                }
            }
            
            completion(posts)
        })
        
    }
    
    func fetchPosts(completion: @escaping PostsReceived) {
        let postData = databaseRef.child("Posts/")
        var posts: [Post] = []
        
        postData.observeSingleEvent(of: .value, with: { snapshot in
            for child in snapshot.children {
                let snap = child as! DataSnapshot
                
                for children in snap.children {
                    print("User Child: \(children)")
                    let childSnap = children as! DataSnapshot
                    let childSnapDict = childSnap.value as! NSDictionary
                    if childSnapDict["userID"] != nil {
                        let post = Post(snapshot: children as! DataSnapshot)
                        posts.append(post)
                    }
                }
            }
            
            completion(posts)
        })
    }
    
    typealias ProfileFound = (Profile) -> Void
    
    func userFromId(id: String, completion: @escaping ProfileFound) {
        let userData = databaseRef.child("Users/\(id)/")
        
        userData.observeSingleEvent(of: .value, with: { snapshot in
            let capturedProfile = Profile(snapshot: snapshot)
            completion(capturedProfile)
        })
    }
    
    func likePost(post: Post, completion: @escaping PostLikes) {
        let currentUser = Auth.auth().currentUser
        let likeTimestamp = Date().timeIntervalSince1970
        let likeDict = ["userID": currentUser!.uid, "timestamp": likeTimestamp] as [String : Any]
        let userData = databaseRef.child("Posts/\(post.userID!)/\(post.key)/likers/\(currentUser!.uid)")
        
        userData.updateChildValues(likeDict) { (error, reference) in
            if error == nil {
                print(reference)
                self.incrementLikes(post: post, completion: completion)
            } else {
                print(error?.localizedDescription)
            }
        }
    }
    
    typealias PostLikes = (Int) -> Void
    
    func incrementLikes(post: Post, completion: @escaping PostLikes) {
        let postData = databaseRef.child("Posts/\(post.userID!)/\(post.key)")
        
        postData.observeSingleEvent(of: .value, with: { (snapshot) in
            let post = Post(snapshot: snapshot)
            let newLikeDict = ["likes": post.likes! + 1]
            completion(post.likes! + 1)
            postData.updateChildValues(newLikeDict)
        })
    }
    
    func decrementLikes(post: Post, completion: @escaping PostLikes) {
        let postData = databaseRef.child("Posts/\(post.userID!)/\(post.key)")
        
        postData.observeSingleEvent(of: .value, with: { (snapshot) in
            let post = Post(snapshot: snapshot)
            let newLikeDict = ["likes": post.likes! - 1]
            completion(post.likes! - 1)
            postData.updateChildValues(newLikeDict)
        })
    }
    
    func dislikePost(post: Post, completion: @escaping PostLikes) {
        let currentUser = Auth.auth().currentUser
        let postData = databaseRef.child("Posts/\(post.userID!)/\(post.key)/likers/")
        
        postData.child("\(currentUser!.uid)").removeValue { (error, reference) in
            if error == nil {
                print(reference)
                self.decrementLikes(post: post, completion: completion)
            } else {
                print(error?.localizedDescription)
            }
        }
    }
    
    typealias PostLiked = (Bool) -> Void
    
    func isPostLiked(post: Post, completion: @escaping PostLiked) {
        let currentUser = Auth.auth().currentUser
        let postData = databaseRef.child("Posts/\(post.userID!)/\(post.key)/likers/\(currentUser!.uid)")
        
        postData.observeSingleEvent(of: .value, with: { snapshot in
            print("POstData: \(postData) Snap: \(snapshot)")
            if snapshot.exists() {
                completion(true)
            } else {
                completion(false)
            }
        })
    }
    
    func isPostSaved(post: Post, completion: @escaping PostLiked) {
        let currentUser = Auth.auth().currentUser
        let postData = databaseRef.child("Posts/\(post.userID!)/\(post.key)/usersWhoSaved/\(currentUser!.uid)/")
        
        postData.observeSingleEvent(of: .value, with: { snapshot in
            if snapshot.exists() {
                completion(true)
            } else {
                completion(false)
            }
        })
    }
    
    func postComment(post: Post, comment: String, user: User, completion: @escaping (DatabaseReference) -> Void) {
        let postTimestamp = Date().timeIntervalSince1970
        var commentDict: [String: Any] = ["timestamp": postTimestamp, "userID": "\(user.uid)", "comment": comment]
        
        var hashtags: [String] = []
        var mentions: [String] = []
        
        
        let words = comment.components(separatedBy: " ")
        
        for word in words {
            if word.hasPrefix("#") {
                hashtags.append(word)
            } else if word.hasPrefix("@") {
                mentions.append(word)
            }
        }
        
        
        // If hashtags isn't empty
        if hashtags != [] {
            let hashtagsString = hashtags.joined(separator: " ")
            commentDict["hashtags"] = hashtagsString
        }
        
        if mentions != [] {
            let mentionsString = mentions.joined(separator: " ")
            commentDict["mentions"] = mentionsString
        }
        
        let randomKey = databaseRef.child("Posts/\(post.userID!)/\(post.key)").childByAutoId().key
        
        let commentData = databaseRef.child("Posts/\(post.userID!)/\(post.key)/comments/\(randomKey)")
                
        commentData.updateChildValues(commentDict) { (error, reference) in
            if error == nil {
                completion(reference)
                print("Post Comment Succession")
            } else {
                print(error!.localizedDescription)
            }
        }
    }
    
    func deleteCaption(post: Post, completion: @escaping (DatabaseReference) -> Void) {
        let postData = databaseRef.child("Posts/\(post.userID!)/\(post.key)/caption")
        
        postData.removeValue { (error, reference) in
            if error == nil {
                print("Caption removed successfully!")
                completion(reference)
            } else {
                print("There was an error removing the caption \(error!.localizedDescription)")
            }
        }
    }
    
    func deleteComment(post: Post, comment: Comment, completion: @escaping (DatabaseReference) -> Void) {
        let commentData = databaseRef.child("Posts/\(post.userID!)/\(post.key)/comments/\(comment.key)/")
        
        commentData.removeValue { (error, reference) in
            if error == nil {
                print("Comment successfully deleted ")
                completion(reference)
            } else {
                print("Error deleting comment \(error!.localizedDescription)")
            }
        }
    }
    
    typealias ReturnImage = (UIImage) -> Void
    func retrievePostPicture(imageURL: String, completion: @escaping ReturnImage) {
        
        var storageRef: Storage {
            return Storage.storage()
        }
        
        storageRef.reference(forURL: imageURL).getData(maxSize: 5 * 1024 * 1024) { (imgData, error) in
            if error == nil {
                if let image = imgData {
                    DispatchQueue.main.async {                        
                        let newImage = UIImage(data: image)
                        completion(newImage!)
                    }
                }
            } else {
                print(error?.localizedDescription)
            }
        }
    }
    
    func retrieveProfilePicture(userID: String, completion: @escaping ReturnImage) {
        let userData = databaseRef.child("Users/\(userID)/")
        
        var storageRef: Storage {
            return Storage.storage()
        }
        
        userData.observeSingleEvent(of: .value, with: { snapshot in
            let profile = Profile(snapshot: snapshot)
            
            if let profilePic = profile.photoURL {
                storageRef.reference(forURL: profilePic).getData(maxSize: 5 * 1024 * 1024, completion: { (imgData, error) in
                    if error == nil {
                        if let image = imgData {
                            DispatchQueue.main.async {
                                let profileImage = UIImage(data: image)
                                completion(profileImage!)
                            }
                        }
                    } else {
                        print(error!.localizedDescription)
                    }
                })
            } else {
                let noProfilePic = #imageLiteral(resourceName: "user-placeholder.jpg")
                completion(noProfilePic)
            }
        })
    }
    
    typealias ReturnUserIDs = ([String]) -> Void
    typealias ReturnLikers = ([Profile]) -> Void
    
    func fetchPostLikers(post: Post, completion: @escaping ReturnUserIDs) {
        let postData = databaseRef.child("Posts/\(post.userID!)/\(post.key)/likers/")
        
        postData.observeSingleEvent(of: .value, with: { snapshot in
            if snapshot.exists() {
                var userIDs: [String] = []
                let childSnapDict = snapshot.value as! [String: Any]
            
                for (id, _) in childSnapDict {
                    userIDs.append(id)
                }
            
                completion(userIDs)
            }
        })
    }
    
    func fetchPostLikes(post: Post, completion: @escaping ReturnLikers) {
        fetchPostLikers(post: post) { (userIDs) in
            var profiles: [Profile] = []
            var loopCount = 0
            for id in userIDs {
                self.userFromId(id: id, completion: { (profile) in
                    loopCount = loopCount + 1
                    profiles.append(profile)
                    
                    if loopCount == userIDs.count {
                        completion(profiles)
                    }
                })
            }
        }
    }
    
    typealias CommentsReceived = ([Comment]) -> Void
    
    func fetchComments(post: Post, completion: @escaping CommentsReceived) {
        let userData = databaseRef.child("Posts/\(post.userID!)/\(post.key)/comments")
        
        userData.observeSingleEvent(of: .value, with: { (snapshot) in
            var comments: [Comment] = []
            for children in snapshot.children {
                let comment = Comment(snapshot: children as! DataSnapshot)
                comments.append(comment)
            }
            completion(comments)
        })
    }
    
    func fetchUser(user: User, completion: @escaping ProfileFound) {
        let userData = databaseRef.child("Users/\(user.uid)")
        userData.observeSingleEvent(of: .value, with: { snapshot in
            let profile = Profile(snapshot: snapshot)
            completion(profile)
        })
    }
    
    func fetchUserAlot(user: User, completion: @escaping ProfileFound) {
        let userData = databaseRef.child("Users/\(user.uid)")
        userData.observe(.value, with: { snapshot in
            let profile = Profile(snapshot: snapshot)
            completion(profile)
        })
    }
    
    typealias PostReloaded = (Post) -> Void
    
    func reloadPost(post: Post, completion: @escaping PostReloaded) {
        let userData = databaseRef.child("Posts/\(post.userID!)/\(post.key)")
        
        userData.observeSingleEvent(of: .value, with: { snapshot in
            let post = Post(snapshot: snapshot)
            completion(post)
        })
    }
    
    func savePost(post: Post, currentUser: User, completion: @escaping PostUploaded) {
        let userDict = ["userID": currentUser.uid]
        let savedDict = ["key": post.key, "userID": post.userID!]
        let postData = databaseRef.child("Posts/\(post.userID!)/\(post.key)/usersWhoSaved/\(currentUser.uid)")
        let userData = databaseRef.child("Users/\(currentUser.uid)/savedPosts/\(post.userID!)/\(post.key)")
        
        postData.updateChildValues(userDict) { (error, reference) in
            if error == nil {
                userData.updateChildValues(savedDict)
                completion(true)
            } else {
                print("User can't save? \(error!.localizedDescription)")
            }
        }
    }
    
    func unSavePost(post: Post, currentUser: User, completion: @escaping PostUploaded) {
        let postData = databaseRef.child("Posts/\(post.userID!)/\(post.key)/usersWhoSaved/\(currentUser.uid)")
        let savedData = databaseRef.child("Users/\(currentUser.uid)/savedPosts/\(post.userID!)/\(post.key)")

        postData.removeValue { (error, reference) in
            if error == nil {
                print("Reference: \(reference)")
                savedData.removeValue()
                completion(true)
            } else {
                print("User can't unsave? \(error!.localizedDescription)")
            }
        }
    }
    
    typealias SavedPostsReceived = ([Post]) -> Void
    func usersSavedPosts(currentUser: User, completion: @escaping SavedPostsReceived) {
        let savedPostsData = databaseRef.child("Users/\(currentUser.uid)/savedPosts/")
        
        savedPostsData.observeSingleEvent(of: .value, with: { snapshot in
            var posts: [SavedPosts] = []
            var loopCount = 0
            
            for children in snapshot.children {
                let childSnap = children as! DataSnapshot
                let childSnapDict = childSnap.value as! [String: Any]
                for (_, value) in childSnapDict {
                    let dataDict = value as! [String: Any]
                    if let userID = dataDict["userID"] as? String, let key = dataDict["key"] as? String {
                        loopCount = loopCount + 1
                        let savedPosts = SavedPosts(key: key, userID: userID)
                        posts.append(savedPosts)
                        print("SavedPosts: \(savedPosts)")
                    }
                }
            }
            self.fetchUsersSavedPosts(savedPosts: posts, completion: completion)
        })
    }
    
    func usersMentionPosts(username: String, completion: @escaping SavedPostsReceived) {
        let postData = databaseRef.child("Posts/")
        var posts: [Post] = []
        
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
                        let post = Post(snapshot: children as! DataSnapshot)
                        if let mentions = post.mentions {
                            if mentions.contains("@\(username)") && mentions.characters.count == username.characters.count + 1 {
                                print("TRUE")
                                posts.append(post)
                            }
                        }
                    }
                }
                
                if loopCount == childLoopCount {
                    completion(posts)
                }
            }
        })
    }
    
    func fetchUsersSavedPosts(savedPosts: [SavedPosts], completion: @escaping SavedPostsReceived) {
        var loopCount = 0
        let postData = databaseRef.child("Posts/")
        var posts: [Post] = []
        for post in savedPosts {
            postData.child("\(post.userID!)/\(post.key!)/").observeSingleEvent(of: .value, with: { snapshot in
                loopCount = loopCount + 1
                let childSnapDict = snapshot.value as! NSDictionary
                if childSnapDict["userID"] != nil {
                    let userPost = Post(snapshot: snapshot)
                    posts.append(userPost)
                }
                
                if loopCount == savedPosts.count {
                    completion(posts)
                }
            })
        }
    }
    
    func fetchPosts(with hashtag: String, completion: @escaping PostsReceived) {
        let postData = databaseRef.child("Posts/")
        var posts: [Post] = []
        
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
                        let post = Post(snapshot: children as! DataSnapshot)
                        if let hashtags = post.hashtags {
                            if hashtags.contains(hashtag) {
                                print("Appened Post")
                                posts.append(post)
                            }
                        }
                    }
                }
                
                if loopCount == childLoopCount {
                    completion(posts)
                }
            }
        })
    }
    
    typealias PostDeletion = (DatabaseReference) -> Void
    
    func deletePost(post: Post, completion: @escaping PostDeletion) {
        let postData = databaseRef.child("Posts/\(post.userID!)/\(post.key)/")
        
        postData.observeSingleEvent(of: .value, with: { snapshot in
            if snapshot.exists() {
                postData.removeValue(completionBlock: { (error, reference) in
                    if error != nil {
                        print("Error Deleting Post: \(error!.localizedDescription)")
                    } else {
                        completion(reference)
                    }
                })
            }
        })
    }
    
    func reportPost(post: Post, reporter: String) {
        let postData = databaseRef.child("Posts/\(post.userID!)/\(post.key)/")
        
        postData.observeSingleEvent(of: .value, with: { snapshot in
            if snapshot.exists() {
                let reportersDict: [String: String] = ["Reporter": reporter]
                let reportersData = postData.child("Reporters/")
                
                
                reportersData.updateChildValues(reportersDict, withCompletionBlock: { (error, reference) in
                    if error != nil {
                        print("Error Reporting Post: \(error!.localizedDescription)")
                    } else {
                        print("User Has Reported Post: \(reference)")
                    }
                })
            }
        })
    }
}




