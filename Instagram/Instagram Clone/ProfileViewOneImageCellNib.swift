//
//  ProfileViewOneImageCellNib.swift
//  Instagram Clone
//
//  Created by Fuad on 04/04/2017.
//  Copyright © 2017 FuadAdetoro. All rights reserved.
//

import UIKit

class ProfileViewOneImageCellNib: UICollectionViewCell {
    
    @IBOutlet weak var postedPicture: UIImageView!
    
    func configure(image: UIImage) {
        self.postedPicture.image = image
    }
}
