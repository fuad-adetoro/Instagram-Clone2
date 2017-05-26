//
//  CameraViewController.swift
//  Instagram Clone
//
//  Created by Fuad on 28/03/2017.
//  Copyright © 2017 FuadAdetoro. All rights reserved.
////

import UIKit
import Firebase

class SelectedPhotoViewController: UIViewController {

    @IBOutlet weak var pictureToUpload: UIImageView!
    @IBOutlet weak var captionText: UITextView!
    
    var image: UIImage?
    let postService = PostService()
    
    func postPicture() {
        let currentUser = Auth.auth().currentUser
        postService.createPost(picture: pictureToUpload.image!, caption: captionText.text!, user: currentUser!) { (status) in
            if status {
                self.dismiss(animated: true, completion: nil)
            } else {
                // Do nothing RN
            }
        }
    }
    
    override var prefersStatusBarHidden: Bool {
        return true
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        pictureToUpload.image = image!
        captionText.becomeFirstResponder()
        let shareButton = UIBarButtonItem(title: "Share", style: .done, target: nil, action: #selector(SelectedPhotoViewController.postPicture))
        self.navigationItem.rightBarButtonItem = shareButton
        
        let imageGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(SelectedPhotoViewController.imageZoomcView))
        imageGestureRecognizer.numberOfTapsRequired = 1
        self.pictureToUpload.addGestureRecognizer(imageGestureRecognizer)
    }
    
    func imageZoomcView() {
        self.navigationController?.navigationBar.isHidden = true

        self.view.endEditing(true)
        
        let tempView = UIView()
        tempView.frame = self.view.frame
        tempView.backgroundColor = UIColor.white
        tempView.tag = 911
        
        let imageView = UIImageView(frame: CGRect(x: 0, y: tempView.frame.height/4, width: tempView.frame.width, height: 300))
        imageView.image = pictureToUpload.image
        imageView.contentMode = pictureToUpload.contentMode
        
        tempView.addSubview(imageView)
        self.view.addSubview(tempView)
        
        let removeImageGesture = UITapGestureRecognizer(target: self, action: #selector(SelectedPhotoViewController.removeZoomView))
        removeImageGesture.numberOfTapsRequired = 1
        tempView.addGestureRecognizer(removeImageGesture)
    }
    
    func removeZoomView() {
        self.navigationController?.navigationBar.isHidden = false

        let tempView = self.view.viewWithTag(911)!
        tempView.removeFromSuperview()
        
        captionText.becomeFirstResponder()
    }

}

extension SelectedPhotoViewController: UINavigationBarDelegate {
    func position(for bar: UIBarPositioning) -> UIBarPosition {
        return .topAttached
    }
}
