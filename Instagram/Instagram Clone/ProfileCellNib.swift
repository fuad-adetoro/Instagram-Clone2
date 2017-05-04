//
//  ProfileCellNib.swift
//  Instagram Clone
//
//  Created by Fuad on 31/03/2017.
//  Copyright © 2017 FuadAdetoro. All rights reserved.
//

import UIKit
import Firebase

class ProfileCellNib: UICollectionViewCell {
    
    @IBOutlet weak var profilePicture: UIImageView!
    @IBOutlet weak var postsCountLabel: UILabel!
    @IBOutlet weak var followersCountLabel: UILabel!
    @IBOutlet weak var followingCountLabel: UILabel!
    @IBOutlet weak var displayNameLabel: UILabel!
    @IBOutlet weak var biographLabel: UILabel!
    @IBOutlet weak var editProfileButton: UIButton!
    let authService = AuthService()
    
    override func awakeFromNib() {
        updateViewLayout()
    }
    
    func updateUserPicture(user: FIRUser, image: UIImage) {
        authService.updateProfilePhoto(user: user, picture: image)
    }
    
    func updatePostCount(count: Int) {
        self.postsCountLabel.text = "\(count)"
    }
    
    
    func configure(user: FIRUser) {
        var databaseRef: FIRDatabaseReference {
            return FIRDatabase.database().reference()
        }
        
        let userData = databaseRef.child("Users/\(user.uid)/")
        
        userData.observe(.value, with: { snapshot in
            let user = User(snapshot: snapshot)
            
            if let displayName = user.name {
                self.displayNameLabel.text = displayName
            } else {
                self.displayNameLabel.text = ""
            }
            
            if let bio = user.biograph {
                self.biographLabel.text = bio
            } else {
                self.biographLabel.text = ""
            }
            
            if let profilePicture = user.photoURL {
                var storageRef: FIRStorage {
                    return FIRStorage.storage()
                }
                
                storageRef.reference(forURL: profilePicture).data(withMaxSize: 1 * 1024 * 1024) { (imgData, error) in
                    
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
        })
        
        self.editProfileButton.isEnabled = true
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
}



