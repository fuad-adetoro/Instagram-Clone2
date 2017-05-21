//
//  PostWithCaptionCell.swift
//  Instagram Clone
//
//  Created by Fuad on 28/03/2017.
//  Copyright © 2017 FuadAdetoro. All rights reserved.
///

import UIKit
import Firebase

class PostCellWithCaption: UICollectionViewCell {
    
    @IBOutlet weak var profilePicture: UIImageView!
    @IBOutlet weak var usernameLabel: UIButton!
    @IBOutlet weak var postedPicture: UIImageView!
    @IBOutlet weak var isLikedOutlet: UIButton!
    @IBOutlet weak var timePosted: UILabel!
    @IBOutlet weak var likesLabel: UILabel!
    @IBOutlet weak var captionTextView: UITextView!
    @IBOutlet weak var saveButton: UIButton!
    @IBOutlet weak var optionsButton: UIButton!
        
    var downloadTask: URLSessionDownloadTask!

    var currentPost: Post?
    let user = FIRAuth.auth()?.currentUser
    let postService = PostService()
    let authService = AuthService()
    
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
        
        captionTextView.textContainer.lineFragmentPadding = 0
        captionTextView.textContainerInset = UIEdgeInsets.zero
        
        self.contentView.autoresizingMask = [.flexibleHeight]
    }
    
    override var bounds: CGRect {
        didSet {
            contentView.frame = bounds
        }
    }
    
    func preferredLayoutSizeFittingSize(targetSize: CGSize/*, user: User*/) -> CGSize {
        let originalFrame = self.frame
        
        var frame = self.frame
        frame.size = targetSize
        self.frame = frame
        
        self.setNeedsLayout()
        self.layoutIfNeeded()
        
        // calling this tells the cell to figure out a size for it based on the current items set
        let computedHeight = self.systemLayoutSizeFitting(UILayoutFittingCompressedSize).height
        
        let newSize = CGSize(width:self.frame.width, height: computedHeight)
        
        self.frame = originalFrame
        
        return newSize
    }
    
    func configure(username: String, caption: String) {
        let username = username
        let myString = NSMutableAttributedString(string: "\(username) \(caption)")
        
        // Set an attribute on part of the string
        let myRange = NSRange(location: 0, length: username.characters.count)
        
        let myCustomAttribute = [ NSForegroundColorAttributeName: UIColor.darkGray ]
        myString.addAttributes(myCustomAttribute, range: myRange)
        
        self.captionTextView.attributedText = myString
        self.captionTextView.sizeToFit()
        self.updateConstraints()
    }
    
    func configure(post: Post) {
        self.currentPost = post
        likesLabel.text = "\(post.likes!) likes"
        
        self.usernameLabel.setTitle(post.username!, for: .normal)
                
        let date = Date(timeIntervalSince1970: post.timestamp!)
        self.timePosted.text = date.timeAgoDisplay()
        
        setupPostedPicture(photoURL: post.imageURL!)
        setupProfilePicture(userID: post.userID!)
        
        postService.isPostLiked(post: post) { (status) in
            self.isLiked = status
            self.setupInitialLikeButton()
        }
        
        postService.isPostSaved(post: post) { (status) in
            self.isSaved = status
            self.setupInitialSaveButton()
        }
        
        self.updateConstraints()
    }
    
    func setupPostedPicture(photoURL: String) {
        if let url = URL(string: photoURL) {
            DispatchQueue.main.async {
                self.downloadTask = self.postedPicture.loadImage(url: url)
            }
        }
    }
    
    func setupProfilePicture(userID: String) {
        var storageRef: FIRStorage {
            return FIRStorage.storage()
        }
        
        authService.userFromId(id: userID) { (user) in
            if let profilePicture = user.photoURL {
                storageRef.reference(forURL: profilePicture).data(withMaxSize: 5 * 1024 * 1024, completion: { (imgData, error) in
                    if error == nil {
                        if let image = imgData {
                            DispatchQueue.main.async {
                                self.profilePicture.image = UIImage(data: image)
                            }
                        }
                    } else {
                        print(error!.localizedDescription)
                    }
                })
            }
        }
    }
    
    func setupInitialSaveButton() {
        if isSaved {
            self.saveButton.setImage(#imageLiteral(resourceName: "savedpicture"), for: .normal)
        } else {
            self.saveButton.setImage(#imageLiteral(resourceName: "savepicture"), for: .normal)
        }
    }
    
    func setupInitialLikeButton() {
        if isLiked {
            self.isLikedOutlet.setImage(#imageLiteral(resourceName: "pictureliked"), for: .normal)
        } else {
            self.isLikedOutlet.setImage(#imageLiteral(resourceName: "likebutton"), for: .normal)
        }
    }
}
