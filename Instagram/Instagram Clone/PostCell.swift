//
//  PostWithCaptionCell.swift
//  Instagram Clone
//
//  Created by Fuad on 28/03/2017.
//  Copyright © 2017 FuadAdetoro. All rights reserved.
//

import UIKit
import Firebase

class PostCell: UICollectionViewCell {

    @IBOutlet weak var profilePicture: UIImageView!
    @IBOutlet weak var usernameLabel: UIButton!
    @IBOutlet weak var postedPicture: UIImageView!
    @IBOutlet weak var isLikedOutlet: UIButton!
    @IBOutlet weak var timePosted: UILabel!
    @IBOutlet weak var likesLabel: UILabel!
    
    var currentPost: Post?
    let postService = PostService()
    
    @IBAction func isLikedAction(_ sender: Any) {
        if currentPost != nil {
            if !isLiked {
                likePost(post: currentPost!)
            } else {
                dislikePost(post: currentPost!)
            }
            
            isLiked = !isLiked
        }
    }
    
    func likePost(post: Post) {
        postService.likePost(post: post) { (likes) in
            self.likesLabel.text = "\(likes) likes"
        }
        isLikedOutlet.setImage(#imageLiteral(resourceName: "pictureliked"), for: .normal)
    }
    
    func dislikePost(post: Post) {
        postService.dislikePost(post: post) { (likes) in
            self.likesLabel.text = "\(likes) likes"
        }
        isLikedOutlet.setImage(#imageLiteral(resourceName: "likebutton"), for: .normal)
    }
    
    var isLiked = false
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
        self.profilePicture.layer.masksToBounds = true
        self.profilePicture.layer.cornerRadius = self.profilePicture.frame.width / 2
    }
    
    func configure(post: Post) {
        var databaseRef: FIRDatabaseReference {
            return FIRDatabase.database().reference()
        }
        
        var storageRef: FIRStorage {
            return FIRStorage.storage()
        }
        
        likesLabel.text = "\(post.likes!) likes"
        
        postService.userFromId(id: post.userID!) { (user) in
            self.usernameLabel.setTitle(user.username!, for: .normal)
            
            if let profilePicture = user.photoURL {
                storageRef.reference(forURL: profilePicture).data(withMaxSize: 1 * 1024 * 1024, completion: { (imgData, error) in
                    if error == nil {
                        if let image = imgData {
                            DispatchQueue.main.async {
                                self.profilePicture.image = UIImage(data: image)
                            }
                        }
                    } else {
                        print(error?.localizedDescription)
                    }
                })
            }
        }
        
        storageRef.reference(forURL: post.imageURL!).data(withMaxSize: 1 * 1024 * 1024) { (imgData, error) in
            if error == nil {
                if let image = imgData {
                    DispatchQueue.main.async {
                        self.postedPicture.image = UIImage(data: image)
                    }
                }
            } else {
                print(error?.localizedDescription)
            }
        }
        
        let date = Date(timeIntervalSince1970: post.timestamp!)
        self.timePosted.text = date.timeAgoDisplay()
        
        let postData = databaseRef.child("Posts/\(post.userID!)/\(post.key)/")
        
        postData.child("likers/\(post.userID!)").observeSingleEvent(of: .value, with: { snapshot in
            if snapshot.exists() {
                self.isLiked = true
                self.setupInitialLikeButton()
            } else {
                self.isLiked = false
                self.setupInitialLikeButton()
            }
        })
    }
    
    func setupInitialLikeButton() {
        if isLiked {
            self.isLikedOutlet.setImage(#imageLiteral(resourceName: "pictureliked"), for: .normal)
        } else {
            self.isLikedOutlet.setImage(#imageLiteral(resourceName: "likebutton"), for: .normal)
        }
    }
}
