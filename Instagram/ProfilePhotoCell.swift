//
//  ProfilePhotoCell.swift
//  Instagram Clone
//
//  Created by Fuad on 28/03/2017.
//  Copyright © 2017 FuadAdetoro. All rights reserved.
//

import UIKit
import Firebase

class ProfilePhotoCell: UICollectionViewCell {
    @IBOutlet weak var usersUploadedPhoto: UIImageView!
    
    override func awakeFromNib() {
        // Do nothing
    }
    
    func configure(post: Post) {
        var storageRef: FIRStorage {
            return FIRStorage.storage()
        }
        
        storageRef.reference(forURL: post.imageURL!).data(withMaxSize: 5 * 1024 * 1024) { (imgData, error) in
            if let error = error as? NSError {
                print(error.localizedDescription)
            } else {
                if let image = imgData {
                    self.usersUploadedPhoto.image = UIImage(data: image)
                }
            }
        }
    }
}
