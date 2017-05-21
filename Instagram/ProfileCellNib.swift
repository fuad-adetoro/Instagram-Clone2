//
//  ProfileCellNib.swift
//  Instagram Clone
//
//  Created by Fuad on 31/03/2017.
//  Copyright © 2017 FuadAdetoro. All rights reserved.
///

import UIKit
import Firebase

class ProfileCellNib: UICollectionViewCell {
    
    @IBOutlet weak var followingView: UIView!
    @IBOutlet weak var followersView: UIView!
    @IBOutlet weak var profilePicture: UIImageView!
    @IBOutlet weak var postsCountLabel: UILabel!
    @IBOutlet weak var followersCountLabel: UILabel!
    @IBOutlet weak var followingCountLabel: UILabel!
    @IBOutlet weak var displayNameLabel: UILabel!
    @IBOutlet weak var biographLabel: UILabel! {
        didSet {
            self.biographLabel.sizeToFit()
        }
    }
    
    @IBOutlet weak var editProfileButton: UIButton!
    
    let authService = AuthService()
    let accountService = AccountService()
    var user: User?
    var currentUser: FIRUser?
    
    var collectionViewHeight: CGFloat?
    
    override func awakeFromNib() {
        
    }
    
    override func layoutSubviews() {
        self.layoutIfNeeded()
        
        updateViewLayout()
    }
    
    func updateUserPicture(user: FIRUser, image: UIImage) {
        authService.updateProfilePhoto(user: user, picture: image)
    }
    
    func updatePostCount(count: Int) {
        self.postsCountLabel.text = "\(count)"
    }
    
    var followingUser = false
    
    func interactiveButton(user: User, currentUser: FIRUser){
        let userData = FIRDatabase.database().reference(withPath: "Users/\(currentUser.uid)/following/\(user.userID!)")
        
        userData.observeSingleEvent(of: .value, with: { snapshot in
            if snapshot.exists() {
                self.editProfileButton.setTitle("Following", for: .normal)
                self.editProfileButton.layer.borderColor = UIColor.clear.cgColor
                self.editProfileButton.backgroundColor = UIColor.green
                self.editProfileButton.addTarget(self, action: #selector(ProfileCellNib.unFollowUser), for: .touchUpInside)
                self.followingUser = true
            } else {
                self.editProfileButton.setTitle("Follow", for: .normal)
                self.editProfileButton.layer.borderColor = UIColor.green.cgColor
                self.editProfileButton.backgroundColor = UIColor.clear
                self.editProfileButton.addTarget(self, action: #selector(ProfileCellNib.followUser), for: .touchUpInside)
                self.followingUser = false
            }
        })
    }
    
    func updateActivityCount(user: User) {
        var databaseRef: FIRDatabaseReference {
            return FIRDatabase.database().reference()
        }
        
        let userData = databaseRef.child("Users/\(user.userID!)/")
        
        userData.observeSingleEvent(of: .value, with: { snapshot in
            let user = User(snapshot: snapshot)
            
            if let following = user.following {
                self.followingCountLabel.text = "\(following.count)"
            } else {
                self.followingCountLabel.text = "0"
            }
            
            if let followers = user.followers {
                self.followersCountLabel.text = "\(followers.count)"
            } else {
                self.followersCountLabel.text = "0"
            }
        })
    }
    
    func followUser() {
        if user != nil, currentUser != nil {
            accountService.followUser(userID: user!.userID!, currentUser: currentUser!)
            interactiveButton(user: user!, currentUser: currentUser!)
            followingUser = true
            updateActivityCount(user: user!)
        }
    }
    
    func unFollowUser() {
        if user != nil, currentUser != nil {
            accountService.unFollowUser(userID: user!.userID!, currentUser: currentUser!)
            interactiveButton(user: user!, currentUser: currentUser!)
            followingUser = false
            updateActivityCount(user: user!)
        }
    }
    
    func configure(biograph: String?, displayName: String?) {
        
        if let username = displayName {
            self.displayNameLabel.text = username
            self.displayNameLabel.sizeToFit()
        }
        
        if let bio = biograph {
            self.biographLabel.text = bio
            self.biographLabel.sizeToFit()
        } else {
            self.biographLabel.sizeThatFits(CGSize(width: self.frame.width, height: 0))
        }
        
        self.updateConstraints()
    }
    
    func configure(user: User) {
        self.user = user
        let currentUser = FIRAuth.auth()?.currentUser
        self.currentUser = currentUser!
        
        if let following = user.following {
            self.followingCountLabel.text = "\(following.count)"
        } else {
            self.followingCountLabel.text = "0"
        }
        
        if let followers = user.followers {
            self.followersCountLabel.text = "\(followers.count)"
        } else {
            self.followersCountLabel.text = "0"
        }
        
        if let displayName = user.name {
            self.displayNameLabel.text = displayName
            self.displayNameLabel.sizeToFit()
            self.updateConstraints()
        } else {
            self.displayNameLabel.text = ""
        }
        
        if let bio = user.biograph {
            self.biographLabel.text = bio
            self.biographLabel.sizeToFit()
        } else {
            self.biographLabel.text = ""
        }
        
        if let profilePicture = user.photoURL {
            var storageRef: FIRStorage {
                return FIRStorage.storage()
            }
            
            storageRef.reference(forURL: profilePicture).data(withMaxSize: 5 * 1024 * 1024) { (imgData, error) in
                
                if error == nil {
                    DispatchQueue.main.async {
                        if let data = imgData {
                            self.profilePicture.image = UIImage(data: data)
                        }
                    }
                } else {
                    print(error?.localizedDescription)
                }
            }
        } else {
            self.profilePicture.image = #imageLiteral(resourceName: "user-placeholder.jpg")
        }
        
        self.updateConstraints()
    }
    
    func updateViewLayout() {
        self.profilePicture.layer.masksToBounds = true
        self.profilePicture.layer.cornerRadius = self.profilePicture.frame.width / 2
        
        self.editProfileButton.layer.borderWidth = 1.0
        
        let borderColor = UIColor(red: 219/255.0, green: 219/255.0, blue: 219/255.0, alpha: 1.0).cgColor
        
        self.editProfileButton.layer.borderColor = borderColor
        self.editProfileButton.layer.masksToBounds = true
        self.editProfileButton.layer.cornerRadius = 3.0
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
}



