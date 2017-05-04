//
//  CameraViewController.swift
//  Instagram Clone
//
//  Created by Fuad on 28/03/2017.
//  Copyright © 2017 FuadAdetoro. All rights reserved.
//

import UIKit
import Firebase

class CameraViewController: UIViewController {

    @IBOutlet weak var pictureToUpload: UIImageView!
    @IBOutlet weak var captionText: UITextView!
    @IBOutlet weak var removePicture: UIButton!
    @IBOutlet weak var postPictureOutlet: UIButton!

    var image: UIImage?
    let postService = PostService()
    
    @IBAction func postPicture(_ sender: Any) {
        let currentUser = FIRAuth.auth()!.currentUser
        let user = currentUser!
        postService.createPost(picture: pictureToUpload.image!, caption: captionText.text!, user: user)
    }
    
    @IBAction func removePic(_ sender: Any) {
        self.removePicture.isHidden = true
        self.pictureToUpload.image = nil
        self.postPictureOutlet.isEnabled = false
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()

        let pictureToUploadGesture = UITapGestureRecognizer(target: self, action: #selector(CameraViewController.showPhotoMenu))
        pictureToUploadGesture.numberOfTapsRequired = 1
        self.pictureToUpload.addGestureRecognizer(pictureToUploadGesture)
    }
    
    func show(image: UIImage) {
        self.pictureToUpload.image = image
        self.removePicture.isHidden = false
        self.postPictureOutlet.isEnabled = true
    }

}

extension CameraViewController: UIImagePickerControllerDelegate, UINavigationControllerDelegate {
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
