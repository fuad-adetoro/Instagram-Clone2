//
//  SearchViewController.swift
//  Instagram Clone
//
//  Created by Fuad on 01/04/2017.
//  Copyright © 2017 FuadAdetoro. All rights reserved.
//

import UIKit
import Firebase

class SearchViewController: UIViewController {

    @IBOutlet weak var exploreCollectionView: UICollectionView!
    
    var images: [UIImage] = []
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let cellNib = UINib(nibName: "ImagePostedCellNib", bundle: nil)
        
        exploreCollectionView.register(cellNib, forCellWithReuseIdentifier: "ImagePostedCellNib")
        
        let currentUser = FIRAuth.auth()?.currentUser
        let user = currentUser!
        
        exploreCollectionView.contentInset = UIEdgeInsets(top: 82, left: 0, bottom: 0, right: 0)
        
        captureImages(user: user)
    }
    
    func captureImages(user: FIRUser) {
        var databaseRef: FIRDatabaseReference {
            return FIRDatabase.database().reference()
        }
        
        let userData = databaseRef.child("Posts/\(user.uid)")
        
        userData.observe(.value, with: { snapshot in
            print("SNAPSHOT CAPTURE: \(snapshot)")
            for child in snapshot.children {
                let post = Post(snapshot: child as! FIRDataSnapshot)
                
                if let postedPicture = post.imageURL {
                    var storageRef: FIRStorage {
                        return FIRStorage.storage()
                    }
                    
                    storageRef.reference(forURL: postedPicture).data(withMaxSize: 5 * 1024 * 1024, completion: { (imgData, error) in
                        if error == nil {
                            if let data = imgData {
                                if let imageFromData = UIImage(data: data) {
                                    self.images.append(imageFromData)
                                    self.exploreCollectionView.reloadData()
                                }
                            }
                        }
                    })
                }
            }
        })
    }

}

extension SearchViewController: UICollectionViewDataSource {
    func numberOfSections(in collectionView: UICollectionView) -> Int {
        return 1
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return self.images.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "ImagePostedCellNib", for: indexPath) as! ImagePostedCellNib
        
        let image = images[indexPath.row]
        cell.configure(image: image)
        
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAtIndexPath indexPath: IndexPath) -> CGSize {
        let layout = collectionView.collectionViewLayout as! UICollectionViewFlowLayout
        layout.sectionInset = UIEdgeInsets(top: 3, left: 3, bottom: 3, right: 3)
        layout.minimumInteritemSpacing = 03
        layout.minimumLineSpacing = 03
        layout.invalidateLayout()
            
        return CGSize(width: view.frame.size.width / 3 - 6, height: view.frame.size.width / 3 - 6)
        
    }
    
    // inter-spacing
    
    func collectionView(collectionView: UICollectionView,
                        layout collectionViewLayout: UICollectionViewLayout,
                        minimumInteritemSpacingForSectionAtIndex section: Int) -> CGFloat {
        return 1.0
    }
    
    // line-spacing
    
    func collectionView(collectionView: UICollectionView, layout
        collectionViewLayout: UICollectionViewLayout,
                        minimumLineSpacingForSectionAtIndex section: Int) -> CGFloat {
        return 1.0
    }
}

extension SearchViewController: UISearchBarDelegate {
    func position(for bar: UIBarPositioning) -> UIBarPosition {
        return .topAttached
    }
}
