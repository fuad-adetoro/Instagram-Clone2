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
    
    func createPost(picture: UIImage, caption: String, user: FIRUser) {
        var noCaption = true
        
        if !caption.isEmpty {
            noCaption = false
        }
        
        let data = UIImageJPEGRepresentation(picture, 1 * 1024 * 1024)! as NSData
        
        let postTimestamp = Date().timeIntervalSince1970
        
        let randomKey = databaseRef.child("Users/").childByAutoId().key
        
        let imageRef = storageRef.child("Posts/").child(user.uid).child(randomKey)
        
        let metaData = FIRStorageMetadata()
        metaData.contentType = "image/jpeg"
        
        imageRef.put(data as Data, metadata: metaData) { (newMetaData, error) in
            if error == nil {
                let photoURL = newMetaData!.downloadURL()
                self.createPostInDatabase(noCaption: noCaption, caption: caption, imageURL: String(describing: photoURL!), user: user, key: randomKey, timestamp: postTimestamp)
            } else {
                print(error?.localizedDescription)
            }
        }
    }
    
    func createPostInDatabase(noCaption: Bool, caption: String, imageURL: String, user: FIRUser, key: String, timestamp: TimeInterval) {
        let dictToUpload: [String: Any]
        
        print("timestamp: \(timestamp)")  
        
        if !noCaption {
            dictToUpload = ["caption": caption, "imageURL": imageURL, "timestamp": timestamp, "likes": 0, "userID": "\(user.uid)"]
        } else {
            dictToUpload = ["imageURL": imageURL, "timestamp": timestamp, "likes": 0, "userID": "\(user.uid)"]
        }
        
        print("DICT \(dictToUpload)")
        
        let userData = databaseRef.child("Posts/\(user.uid)/\(key)")
        
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
    
    /*func fetchPosts(key: String, completion: @escaping PostsReceived) {
        let postData = databaseRef.child("Posts/\(key)")
        var posts: [Post] = []
        
        postData.observeSingleEvent(of: .value, with: { snapshot in
            for child in snapshot.children {
                let post = Post(snapshot: child as! FIRDataSnapshot)
                posts.append(post)
            }
            
            completion(posts)
        })
    }*/
    
    func likePost(post: Post, completion: @escaping PostLikes) {
        let likeDict = ["\(post.userID!)": true]
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
        let postData = databaseRef.child("Posts/\(post.userID!)/\(post.key)/likers/")
        
        postData.child("\(post.userID!)").removeValue { (error, reference) in
            if error == nil {
                print(reference)
                self.decrementLikes(post: post, completion: completion)
            } else {
                print(error?.localizedDescription)
            }
        }
    }
    
    func postComment(postOwner: FIRUser, post: Post, comment: String, user: FIRUser) {
        let postTimestamp = Date().timeIntervalSince1970
        let commentDict: [String: Any] = ["timestamp": postTimestamp, "userID": "\(user.uid)", "comment": comment]
        
        let randomKey = databaseRef.child("Posts/\(postOwner.uid)/\(post.key)").childByAutoId().key
        
        let commentData = databaseRef.child("Posts/\(postOwner.uid)/\(post.key)/comments/\(randomKey)")
        
        commentData.updateChildValues(commentDict) { (error, reference) in
            if error == nil {
                print("Post Comment Succession")
            } else {
                print(error!.localizedDescription)
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
}




