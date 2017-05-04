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
    @IBOutlet weak var saveButton: UIButton!
    
    var currentPost: Post?
    var user = FIRAuth.auth()?.currentUser

    let postService = PostService()
    
    @IBAction func savePost(_ sender: Any) {
        if currentPost != nil, user != nil {
            if isSaved {
                unSavePost(post: currentPost!, user: user!)
            } else {
                savePost(post: currentPost!, user: user!)
            }
            
            isSaved = !isSaved
        }
    }
    
    func savePost(post: Post, user: FIRUser) {
        postService.savePost(post: post, currentUser: user) { (saved) in
            if saved {
                self.saveButton.setImage(#imageLiteral(resourceName: "savedpicture"), for: .normal)
            }
        }
    }
    
    func unSavePost(post: Post, user: FIRUser) {
        postService.unSavePost(post: post, currentUser: user) { (unSaved) in
            if unSaved {
                self.saveButton.setImage(#imageLiteral(resourceName: "savepicture"), for: .normal)
            }
        }
    }
    
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
    var isSaved = false
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
        self.profilePicture.layer.masksToBounds = true
        self.profilePicture.layer.cornerRadius = self.profilePicture.frame.width / 2
    }
    
    func configure(post: Post) {
        self.currentPost = post
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
                storageRef.reference(forURL: profilePicture).data(withMaxSize: 5 * 1024 * 1024, completion: { (imgData, error) in
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
        
        storageRef.reference(forURL: post.imageURL!).data(withMaxSize: 5 * 1024 * 1024) { (imgData, error) in
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
        
        postService.isPostLiked(post: post) { (status) in
            self.isLiked = status
            self.setupInitialLikeButton()
        }
        
        postService.isPostSaved(post: post) { (status) in
            self.isSaved = status
            self.setupInitialSaveButton()
        }
        
        postService.retrieveProfilePicture(userID: post.userID!) { (profilePicture) in
            self.profilePicture.image = profilePicture
        }
    }
    
    func setupInitialSaveButton() {
        if isSaved {
            self.saveButton.setImage(#imageLiteral(resourceName: "savedpicture"), for: .normal)
        } else {
            self.saveButton.setImage(#imageLiteral(resourceName: "savepicture"), for: .normal)
        }
    }
    
    override func preferredLayoutAttributesFitting(_ layoutAttributes: UICollectionViewLayoutAttributes) -> UICollectionViewLayoutAttributes {
        let attr: UICollectionViewLayoutAttributes = layoutAttributes.copy() as! UICollectionViewLayoutAttributes
        
        var newFrame = attr.frame
        self.frame = newFrame
        
        self.setNeedsLayout()
        self.layoutIfNeeded()
        
        let desiredHeight: CGFloat = self.contentView.systemLayoutSizeFitting(UILayoutFittingCompressedSize).height
        newFrame.size.height = desiredHeight
        attr.frame = newFrame
        return attr
    }
    
    func setupInitialLikeButton() {
        if isLiked {
            self.isLikedOutlet.setImage(#imageLiteral(resourceName: "pictureliked"), for: .normal)
        } else {
            self.isLikedOutlet.setImage(#imageLiteral(resourceName: "likebutton"), for: .normal)
        }
    }
}
