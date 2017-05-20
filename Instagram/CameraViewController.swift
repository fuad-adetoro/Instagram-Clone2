//
//  NewCameraViewController.swift
//  Instagram
//
//  Created by apple  on 17/04/2017.
//  Copyright © 2017 Instagram. All rights reserved.
//

import UIKit
import Photos

class CameraViewController: UIViewController, UITabBarDelegate {

    @IBOutlet weak var collectionView: UICollectionView!
    
    var images: [UIImage] = []
    var collectedPicture: UIImage?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        grabPhotos()
    }
    
    
    override var prefersStatusBarHidden: Bool {
        return true
    }
    
    @IBAction func cancelButton(_ sender: Any) {
        self.dismiss(animated: true, completion: nil)
    }
    
    @IBAction func nextAction(_ sender: Any) {
        performSegue(withIdentifier: "SelectedPhotoVC", sender: collectedPicture!)
    }
    
    
    func grabPhotos() {
        
        // Using PHImageManager to grab the user's camera roll photos
        let imgManager = PHImageManager.default()
        
        let requestOptions = PHImageRequestOptions()
        requestOptions.isSynchronous = true
        requestOptions.deliveryMode = .highQualityFormat
        
        let fetchOptions = PHFetchOptions()
        // Sort the picture from which was created last to first
        fetchOptions.sortDescriptors = [NSSortDescriptor(key: "creationDate", ascending: false)]
        
        let fetchResult: PHFetchResult = PHAsset.fetchAssets(with: .image, options: fetchOptions)
        
        // Created new images array to hold images in this scope
        var images: [UIImage] = []
        var loopCount = 0
        
        if fetchResult.count > 0 {
            for i in 0..<fetchResult.count {
                imgManager.requestImage(for: fetchResult.object(at: i), targetSize: CGSize(width: self.view.frame.width, height: 300), contentMode: .aspectFill, options: requestOptions, resultHandler: { image, error in
                    if let collectedPicture = image {
                        if i == 0 {
                            // Setting the main image to be by default the first image
                            self.collectedPicture = collectedPicture
                        }
                        
                        // Appending to the images array in the function scope
                        images.append(collectedPicture)
                        loopCount = loopCount + 1
                        if loopCount == fetchResult.count {
                            // if loopCount is complete then make the out-of-scope images array equal to the in-scope images array, also reload the data
                            self.images = images
                            self.collectionView.reloadData()
                        }
                    }
                    
                    if error != nil {
                        print(error!)
                    }
                })
            }
        } else {
            print("user doesn't have a photo")
        }
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "SelectedPhotoVC" {
            let selectedPhotoVC = segue.destination as! SelectedPhotoViewController
            let imageFromSender = sender as! UIImage
            selectedPhotoVC.image = imageFromSender
        }
    }
}

extension CameraViewController: UICollectionViewDataSource {
    func numberOfSections(in collectionView: UICollectionView) -> Int {
        return 2
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        if section == 0 {
            return 1
        } else {
            return images.count
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        
        if indexPath.section == 0 {
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "SelectedPhoto", for: indexPath)
            
            
            if let firstPicture = collectedPicture {
                let imageView = cell.viewWithTag(996) as! UIImageView
                imageView.image = firstPicture
            }
            
            return cell
        } else {
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "CameraFeedPhoto", for: indexPath)
        
            let imageView = cell.viewWithTag(105) as! UIImageView
            let image = images[indexPath.row]
            imageView.image = image
        
            return cell
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAtIndexPath indexPath: IndexPath) -> CGSize {
        
        if indexPath.section == 0 {
            return CGSize(width: self.view.frame.width, height: 300)
        } else {
            let layout = collectionView.collectionViewLayout as! UICollectionViewFlowLayout
            layout.sectionInset = UIEdgeInsets(top: 0, left: 0, bottom: 0, right: 0)
            layout.minimumInteritemSpacing = 0
            layout.minimumLineSpacing = 0
            layout.invalidateLayout()
            
            return CGSize(width: view.frame.size.width / 3, height: view.frame.size.width / 3)
        }
    }
        
}

extension CameraViewController: UICollectionViewDelegate {
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        if indexPath.section != 0 {
            let newImage = images[indexPath.row]
            collectedPicture = newImage
            collectionView.reloadData()
        }
    }
}
