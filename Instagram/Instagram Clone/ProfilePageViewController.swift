//
//  TempProfilePageViewController.swift
//  Instagram Clone
//
//  Created by Fuad on 28/03/2017.
//  Copyright © 2017 FuadAdetoro. All rights reserved.
//

import UIKit
import Firebase

class ProfilePageViewController: UIViewController {
    
    @IBOutlet weak var profileCollectionView: UICollectionView!
    
    var posts: [Post] = []
    let postService = PostService()
    let currentUser = FIRAuth.auth()?.currentUser
    var user: user!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        var cellNib = UINib(nibName: "ProfileCellNib", bundle: nil)
        profileCollectionView.register(cellNib, forCellWithReuseIdentifier: "ProfileCellNib")
        
        cellNib = UINib(nibName: "ProfileOrganizeCellNib", bundle: nil)
        profileCollectionView.register(cellNib, forCellWithReuseIdentifier: "ProfileOrganizeCellNib")
        
        cellNib = UINib(nibName: "ProfilePhotoCell", bundle: nil)
        profileCollectionView.register(cellNib, forCellWithReuseIdentifier: "ProfilePhotoCell")
        
        postService.fetchPosts(user: currentUser!) { (posts) in
            self.posts = posts
            self.profileCollectionView.reloadData()
        }
        
        self.navigationItem.title = currentUser!.displayName
        
    }
    
    var image: UIImage?
    var updatePicture = false
    
    func show(image: UIImage) {
        self.image = image
        self.updatePicture = true
        self.profileCollectionView.reloadData()
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "pushToPost" {
            let viewProfilePostVC = segue.destination as! ViewProfilePostController
            let post = sender as! Post
            viewProfilePostVC.post = post
        } else if segue.identifier == "EditProfile" {
            let navigationController = segue.destination as! UINavigationController
            let editProfileVC = navigationController.topViewController as! EditProfileViewController
            let currentUser = FIRAuth.auth()?.currentUser
            let user = currentUser!
            editProfileVC.user = user
        }
    }
    
    func editProfile() {
        self.performSegue(withIdentifier: "EditProfile", sender: nil)
    }

}

extension ProfilePageViewController: UINavigationBarDelegate {
    func position(for bar: UIBarPositioning) -> UIBarPosition {
        return .topAttached
    }
}

extension ProfilePageViewController: UICollectionViewDataSource {
    func numberOfSections(in collectionView: UICollectionView) -> Int {
        return 3
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        if section == 0 || section == 1 {
            return 1
        }
        
        return posts.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        
        if indexPath.section == 0 {
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "ProfileCellNib", for: indexPath) as! ProfileCellNib
            
            let currentUser = FIRAuth.auth()?.currentUser
            let user = currentUser!
            
            let imageView = cell.profilePicture!
            let tapGesture = UITapGestureRecognizer(target: self, action: #selector(ProfilePageViewController.showPhotoMenu))
            tapGesture.numberOfTapsRequired = 1
            imageView.addGestureRecognizer(tapGesture)
            
            let editProfile = cell.viewWithTag(902100) as! UIButton
            editProfile.addTarget(self, action: #selector(ProfilePageViewController.editProfile), for: .touchUpInside)
            
            cell.updatePostCount(count: self.posts.count)
            
            if updatePicture {
                if let newPicture = image {
                    cell.updateUserPicture(user: user, image: newPicture)
                }
            }
            
            cell.configure(user: user)
            
            return cell
        } else if indexPath.section == 1 {
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "ProfileOrganizeCellNib", for: indexPath)
            
            return cell
        } else {
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "ProfilePhotoCell", for: indexPath) as! ProfilePhotoCell
            
            let post = posts[indexPath.row]
            cell.configure(post: post)
            
            return cell
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAtIndexPath indexPath: IndexPath) -> CGSize {
        
        if indexPath.section == 0 && indexPath.row == 0 {
           print("Height: \(collectionView.bounds.size.height)")
            return CGSize(width: self.view.frame.width, height: CGFloat(150))
        } else if indexPath.section == 1 {
            return CGSize(width: view.frame.size.width, height: CGFloat(52))
        } else {
            let layout = collectionView.collectionViewLayout as! UICollectionViewFlowLayout
            layout.sectionInset = UIEdgeInsets(top: 3, left: 3, bottom: 3, right: 3)
            layout.minimumInteritemSpacing = 03
            layout.minimumLineSpacing = 03
            layout.invalidateLayout()
            
            return CGSize(width: view.frame.size.width / 3 - 6, height: view.frame.size.width / 3 - 6)
        }
        
    }
}

extension ProfilePageViewController: UICollectionViewDelegate {
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        print("Did Select \(indexPath) \(indexPath.row)")
        
        if indexPath.section == 2 {
            let post = posts[indexPath.row]
            self.performSegue(withIdentifier: "pushToPost", sender: post)
        }
    }
}


extension ProfilePageViewController: UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    func takePhotoWithCamera() {
        let imagePicker = UIImagePickerController()
        imagePicker.sourceType = .camera
        imagePicker.delegate = self
        imagePicker.allowsEditing = true
        present(imagePicker, animated: true, completion: nil)
    }
    
    func photoFromLibrary() {
        let imagePicker = UIImagePickerController()
        imagePicker.sourceType = .photoLibrary
        imagePicker.delegate = self
        imagePicker.allowsEditing = true
        present(imagePicker, animated: true, completion: nil)
    }
    
    func showPhotoMenu() {
        let alertController = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)
        
        let cancelAction = UIAlertAction(title: "Cancel", style: .cancel, handler: nil)
        alertController.addAction(cancelAction)
        
        let takePhotoAction = UIAlertAction(title: "Take Photo with Camera", style: .default) { (alert) in
            self.takePhotoWithCamera()
        }
        alertController.addAction(takePhotoAction)
        
        let photoFromLibrary = UIAlertAction(title: "Pick Photo From Library", style: .default) { (alert) in
            self.photoFromLibrary()
        }
        alertController.addAction(photoFromLibrary)
        
        
        present(alertController, animated: true, completion: nil)
    }
    
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [String : Any]) {
        image = info[UIImagePickerControllerEditedImage] as? UIImage
        
        if let theImage = image {
            show(image: theImage)
        }
        
        dismiss(animated: true, completion: nil)
    }
    
    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        print("CANCEL!")
        dismiss(animated: true, completion: nil)
    }
}
