//
//  ThirdPartySignUpViewController.swift
//  Instagram Clone
//
//  Created by Fuad on 25/03/2017.
//  Copyright © 2017 FuadAdetoro. All rights reserved.
////

import UIKit
import Firebase

class ThirdSignUpViewController: UIViewController {

    @IBOutlet weak var profilePicture: UIButton!
    @IBOutlet weak var fullNameField: UITextField!
    @IBOutlet weak var passwordField: UITextField!
    var email: String?
    var image: UIImage?
    var phoneNumber: String?
    
    @IBAction func addPhoto(_ sender: Any) {
        showPhotoMenu()
    }
    
    @IBAction func nextAction(_ sender: Any) {
        
        let validatedPassword = validatePassword(password: passwordField.text!)
        if validatedPassword.0 == true {
            self.performSegue(withIdentifier: "CreateAccountStepTwo", sender: nil)
        } else {
            let alert = UIAlertController(title: "Error", message: "\(validatedPassword.1!)", preferredStyle: .alert)
            let okAction = UIAlertAction(title: "OK", style: .default, handler: nil)
            alert.addAction(okAction)
            self.present(alert, animated: true, completion: nil)
        }
    }
    
    func validatePassword(password: String) -> (Bool, String?) {
        if password.characters.count < 6 {
            return (false, "Password needs to be at least 6 characters long.")
        }
        
        return (true, nil)
    }
    
    @IBAction func signInAction(_ sender: Any) {
        self.navigationController?.popToRootViewController(animated: true)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
    }

    func show(image: UIImage) {
        self.profilePicture.setImage(image, for: .normal)
        self.profilePicture.layer.masksToBounds = true
        self.profilePicture.layer.cornerRadius = self.profilePicture.frame.width / 2
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "CreateAccountStepTwo" {
            let vc = segue.destination as! FourthSignUpViewController
            guard let email = email, let password = passwordField.text else {
                return
            }
            
            vc.email = email
            vc.password = password
            let fullName = fullNameField.text!
            if fullName.characters.count > 1 {
                vc.fullName = fullName
            }
            
            if let profilePicture = image {
                vc.profilePicture = profilePicture
            }
            
            if let phoneNumber = phoneNumber {
                vc.phoneNumber = phoneNumber
            }
        }
    }
    
}


extension ThirdSignUpViewController: UIImagePickerControllerDelegate, UINavigationControllerDelegate {
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

