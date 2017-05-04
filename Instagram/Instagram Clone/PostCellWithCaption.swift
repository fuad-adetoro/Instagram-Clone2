//
//  PostWithCaptionCell.swift
//  Instagram Clone
//
//  Created by Fuad on 28/03/2017.
//  Copyright © 2017 FuadAdetoro. All rights reserved.
//

import UIKit
import Firebase

class PostCellWithCaption: UICollectionViewCell {
    
    @IBOutlet weak var profilePicture: UIImageView!
    @IBOutlet weak var usernameLabel: UIButton!
    @IBOutlet weak var postedPicture: UIImageView!
    @IBOutlet weak var isLikedOutlet: UIButton!
    @IBOutlet weak var timePosted: UILabel!
    @IBOutlet weak var likesLabel: UILabel!
    @IBOutlet weak var captionTextView: UITextView! {
        didSet {
            captionTextView.textContainer.lineFragmentPadding = 0
            captionTextView.textContainerInset = UIEdgeInsets.zero
            captionTextView.sizeToFit()
        }
    }
    
    var username: String?
    
    var currentPost: Post?
    let postService = PostService()
    let authService = AuthService()
    
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
    
    func setupCaption(username: String, caption: String){
        let myString = NSMutableAttributedString(string: "\(username) \(caption)")
        
        // Set an attribute on part of the string
        let myRange = NSRange(location: 0, length: username.characters.count)
        
        let myCustomAttribute = [ NSForegroundColorAttributeName: UIColor.darkGray ]
        myString.addAttributes(myCustomAttribute, range: myRange)
        
        captionTextView.attributedText = myString
        captionTextView.sizeToFit()
        
        // Add tap gesture recognizer to Text View
        let tap = UITapGestureRecognizer(target: self, action: #selector(myMethodToHandleTap(_:)))
        //tap.delegate = self
        captionTextView.addGestureRecognizer(tap)
        
    }
    
    func myMethodToHandleTap(_ sender: UITapGestureRecognizer) {
        let myTextView = sender.view as! UITextView
        let layoutManager = myTextView.layoutManager
        
        // location of tap in myTextView coordinates and taking the inset into account
        var location = sender.location(in: myTextView)
        location.x -= myTextView.textContainerInset.left;
        location.y -= myTextView.textContainerInset.top;
        
        // character index at tap location
        let characterIndex = layoutManager.characterIndex(for: location, in: myTextView.textContainer, fractionOfDistanceBetweenInsertionPoints: nil)
        
        // if index is valid then do something.
        if characterIndex < myTextView.textStorage.length {
            
            if self.username != nil {
                if characterIndex <= self.username!.characters.count {
                    print("Load Account")
                } else {
                    print("Load Comments")
                }
            }
        }
    }
    
    func configure(post: Post) {
        currentPost = post
        var databaseRef: FIRDatabaseReference {
            return FIRDatabase.database().reference()
        }
        
        var storageRef: FIRStorage {
            return FIRStorage.storage()
        }
        
        likesLabel.text = "\(post.likes!) likes"
        
        authService.userFromId(id: post.userID!) { (user) in
            self.username = user.username!
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
            
            self.setupCaption(username: self.username!, caption: post.caption!)
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
