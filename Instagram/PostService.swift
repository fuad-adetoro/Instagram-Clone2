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
    var databaseRef: FIRDatabaseReference {
        return FIRDatabase.database().reference()
    }
    
    var storageRef: FIRStorageReference {
        return FIRStorage.storage().reference()
    }
    
    typealias PostUploaded = (Bool) -> Void
    
    func createPost(picture: UIImage, caption: String, user: FIRUser, completion: @escaping PostUploaded) {
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
        
        let imageRef = storageRef.child("Posts/").child(user.uid).child(randomKey)
        
        let metaData = FIRStorageMetadata()
        metaData.contentType = "image/jpeg"
        
        imageRef.put(data as Data, metadata: metaData) { (newMetaData, error) in
            if error == nil {
                let photoURL = newMetaData!.downloadURL()
                self.userFromId(id: user.uid, completion: { (user) in
                    self.createPostInDatabase(noCaption: noCaption, caption: caption, imageURL: String(describing: photoURL!), user: user, key: randomKey, timestamp: postTimestamp, hashtags: hashtags, mentions: mentions)
                    completion(true)
                })
            } else {
                print(error?.localizedDescription)
                completion(false)
            }
        }
    }
    
    func createPostInDatabase(noCaption: Bool, caption: String, imageURL: String, user: User, key: String, timestamp: TimeInterval, hashtags: [String], mentions: [String]) {
        let dictToUpload: [String: Any]
        
        print("timestamp: \(timestamp)")  
        
        if !noCaption {
            if hashtags != [] && mentions != [] {
                let hashtagString = hashtags.joined(separator: " ")
                let mentionString = mentions.joined(separator: " ")
                dictToUpload = ["caption": caption, "imageURL": imageURL, "timestamp": timestamp, "likes": 0, "userID": user.userID!, "username": user.username!, "hashtags": hashtagString, "mentions": mentionString]
            } else if hashtags != [] {
                let hashtagString = hashtags.joined(separator: " ")
                dictToUpload = ["caption": caption, "imageURL": imageURL, "timestamp": timestamp, "likes": 0, "userID": user.userID!, "username": user.username!, "hashtags": hashtagString]
            } else if mentions != [] {
                let mentionString = mentions.joined(separator: " ")
                dictToUpload = ["caption": caption, "imageURL": imageURL, "timestamp": timestamp, "likes": 0, "userID": user.userID!, "username": user.username!, "mentions": mentionString]
            } else {
                dictToUpload = ["caption": caption, "imageURL": imageURL, "timestamp": timestamp, "likes": 0, "userID": user.userID!, "username": user.username!]
            }
        } else {
            dictToUpload = ["imageURL": imageURL, "timestamp": timestamp, "likes": 0, "userID": user.userID!, "username": user.username!]
        }
        
        print("DICT \(dictToUpload)")
        
        let userData = databaseRef.child("Posts/\(user.userID!)/\(key)")
        
        userData.setValue(dictToUpload) { (error, reference) in
            if let error = error as? NSError {
                print(error.localizedDescription)
            } else {
                print(reference)
            }
        }
    }
    
    typealias PostsReceived = ([Post]) -> Void
    
    func fetchPosts(user: FIRUser, completion: @escaping PostsReceived) {
        let postData = databaseRef.child("Posts/\(user.uid)/")
        
        postData.observeSingleEvent(of: .value, with: { (snapshot) in
            var posts: [Post] = []
            for children in snapshot.children {
                let childSnap = children as! FIRDataSnapshot
                let childSnapDict = childSnap.value as! NSDictionary
                if childSnapDict["userID"] != nil {
                    let post = Post(snapshot: children as! FIRDataSnapshot)
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
                let childSnap = children as! FIRDataSnapshot
                let childSnapDict = childSnap.value as! NSDictionary
                if childSnapDict["userID"] != nil {
                    let post = Post(snapshot: children as! FIRDataSnapshot)
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
                let snap = child as! FIRDataSnapshot
                
                for children in snap.children {
                    print("User Child: \(children)")
                    let childSnap = children as! FIRDataSnapshot
                    let childSnapDict = childSnap.value as! NSDictionary
                    if childSnapDict["userID"] != nil {
                        let post = Post(snapshot: children as! FIRDataSnapshot)
                        print("User Post: \(post)")
                        posts.append(post)
                        print("User Sent")
                    }
                }
            }
            
            print("User Completion")
            completion(posts)
        })
        
    }
    
    func fetchPosts(completion: @escaping PostsReceived) {
        let postData = databaseRef.child("Posts/")
        var posts: [Post] = []
        
        postData.observeSingleEvent(of: .value, with: { snapshot in
            for child in snapshot.children {
                let snap = child as! FIRDataSnapshot
                
                for children in snap.children {
                    print("User Child: \(children)")
                    let childSnap = children as! FIRDataSnapshot
                    let childSnapDict = childSnap.value as! NSDictionary
                    if childSnapDict["userID"] != nil {
                        let post = Post(snapshot: children as! FIRDataSnapshot)
                        print("User Post: \(post)")
                        posts.append(post)
                        print("User Sent")
                    }
                }
            }
            
            print("User Completion")
            completion(posts)
        })
    }
    
    typealias UserFound = (User) -> Void
    
    func userFromId(id: String, completion: @escaping UserFound) {
        let userData = databaseRef.child("Users/\(id)/")
        
        userData.observeSingleEvent(of: .value, with: { snapshot in
            let capturedUser = User(snapshot: snapshot)
            completion(capturedUser)
        })
    }
    
    func likePost(post: Post, completion: @escaping PostLikes) {
        let currentUser = FIRAuth.auth()?.currentUser
        let likeDict = ["\(currentUser!.uid)": true]
        let userData = databaseRef.child("Posts/\(post.userID!)/\(post.key)/likers/")
        
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
        let currentUser = FIRAuth.auth()?.currentUser
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
        let currentUser = FIRAuth.auth()?.currentUser
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
        let currentUser = FIRAuth.auth()?.currentUser
        let postData = databaseRef.child("Posts/\(post.userID!)/\(post.key)/usersWhoSaved/\(currentUser!.uid)/")
        
        postData.observeSingleEvent(of: .value, with: { snapshot in
            if snapshot.exists() {
                completion(true)
            } else {
                completion(false)
            }
        })
    }
    
    func postComment(post: Post, comment: String, user: FIRUser) {
        let postTimestamp = Date().timeIntervalSince1970
        var commentDict: [String: Any] = ["timestamp": postTimestamp, "userID": "\(user.uid)", "comment": comment]
        
        let randomKey = databaseRef.child("Posts/\(post.userID!)/\(post.key)").childByAutoId().key
        
        let commentData = databaseRef.child("Posts/\(post.userID!)/\(post.key)/comments/\(randomKey)")
        
        commentDict.updateValue("mentions", forKey: "")
        
        commentData.updateChildValues(commentDict) { (error, reference) in
            if error == nil {
                print("Post Comment Succession")
            } else {
                print(error!.localizedDescription)
            }
        }
    }
    
    typealias ReturnImage = (UIImage) -> Void
    func retrievePostPicture(imageURL: String, completion: @escaping ReturnImage) {
        var storageRef: FIRStorage {
            return FIRStorage.storage()
        }
        
        storageRef.reference(forURL: imageURL).data(withMaxSize: 5 * 1024 * 1024) { (imgData, error) in
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
        
        var storageRef: FIRStorage {
            return FIRStorage.storage()
        }
        
        userData.observeSingleEvent(of: .value, with: { snapshot in
            let user = User(snapshot: snapshot)
            
            if let profilePic = user.photoURL {
                storageRef.reference(forURL: profilePic).data(withMaxSize: 5 * 1024 * 1024, completion: { (imgData, error) in
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
    typealias ReturnLikers = ([User]) -> Void
    
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
            var users: [User] = []
            var loopCount = 0
            for id in userIDs {
                self.userFromId(id: id, completion: { (user) in
                    loopCount = loopCount + 1
                    users.append(user)
                    
                    if loopCount == userIDs.count {
                        completion(users)
                    }
                })
            }
        }
    }
    
    typealias CommentsReceived = ([Comments]) -> Void
    
    func fetchComments(post: Post, completion: @escaping CommentsReceived) {
        let userData = databaseRef.child("Posts/\(post.userID!)/\(post.key)/comments")
        
        userData.observeSingleEvent(of: .value, with: { (snapshot) in
            var comments: [Comments] = []
            for children in snapshot.children {
                let comment = Comments(snapshot: children as! FIRDataSnapshot)
                comments.append(comment)
            }
            completion(comments)
        })
    }
    
    func fetchUser(user: FIRUser, completion: @escaping UserFound) {
        let userData = databaseRef.child("Users/\(user.uid)")
        userData.observeSingleEvent(of: .value, with: { snapshot in
            let user = User(snapshot: snapshot)
            completion(user)
        })
    }
    
    func fetchUserAlot(user: FIRUser, completion: @escaping UserFound) {
        let userData = databaseRef.child("Users/\(user.uid)")
        userData.observe(.value, with: { snapshot in
            let user = User(snapshot: snapshot)
            completion(user)
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
    
    func savePost(post: Post, currentUser: FIRUser, completion: @escaping PostUploaded) {
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
    
    func unSavePost(post: Post, currentUser: FIRUser, completion: @escaping PostUploaded) {
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
    func usersSavedPosts(currentUser: FIRUser, completion: @escaping SavedPostsReceived) {
        let savedPostsData = databaseRef.child("Users/\(currentUser.uid)/savedPosts/")
        
        savedPostsData.observeSingleEvent(of: .value, with: { snapshot in
            var posts: [SavedPosts] = []
            var loopCount = 0
            
            for children in snapshot.children {
                print("snapshot value: \(children as! FIRDataSnapshot)")
                let childSnap = children as! FIRDataSnapshot
                let childSnapDict = childSnap.value as! [String: Any]
                print("Child Dict: \(childSnapDict)")
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
                let snap = child as! FIRDataSnapshot
                
                for children in snap.children {
                    let childSnap = children as! FIRDataSnapshot
                    let childSnapDict = childSnap.value as! NSDictionary
                    if childSnapDict["userID"] != nil {
                        let post = Post(snapshot: children as! FIRDataSnapshot)
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
            var childLoopCount = Int(snapshot.childrenCount)
            var loopCount = 0
            
            for child in snapshot.children {
                loopCount = loopCount + 1
                print("CHild: \(child)")
                let snap = child as! FIRDataSnapshot
                
                for children in snap.children {
                    print("User Child: \(children)")
                    let childSnap = children as! FIRDataSnapshot
                    let childSnapDict = childSnap.value as! NSDictionary
                    if childSnapDict["userID"] != nil {
                        let post = Post(snapshot: children as! FIRDataSnapshot)
                        if let hashtags = post.hashtags {
                            if hashtags.contains(hashtag) {
                                print("Appened Post")
                                posts.append(post)
                            }
                        }
                    }
                }
                
                if loopCount == childLoopCount {
                    print("Complete")
                    completion(posts)
                }
            }
        })
    }
    
    typealias PostDeletion = (FIRDatabaseReference) -> Void
    
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




