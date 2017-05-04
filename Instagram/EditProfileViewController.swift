//
//  TempViewController.swift
//  Instagram Clone
//
//  Created by Fuad on 05/04/2017.
//  Copyright © 2017 FuadAdetoro. All rights reserved.
//

import UIKit
import Firebase

class EditProfileViewController: UITableViewController {
    
    @IBOutlet weak var usernameField: UITextField!
    @IBOutlet weak var displayNameField: UITextField!
    @IBOutlet weak var websiteField: UITextField!
    @IBOutlet weak var biographyField: UITextField!
    @IBOutlet weak var emailField: UITextField!
    @IBOutlet weak var phoneNumberField: UITextField!
    @IBOutlet weak var genderField: UITextField!
    
    var username: String!
    var email: String?
    var phoneNumber: String?
    
    var image: UIImage?
    var user: FIRUser!
    let authService = AuthService()
    
    @IBAction func cancelAction(_ sender: Any) {
        self.dismiss(animated: true, completion: nil)
    }
    
    @IBAction func doneAction() {
        let newUsername = usernameField.text!
        let newDisplayName = displayNameField.text!
        let newWebsite = websiteField.text!
        let newBiography = biographyField.text!
        let newEmail = emailField.text!
        let newPhoneNumber = phoneNumberField.text!
        
        var dictToUpload: [String: Any] = [:]
        
        if newUsername != username! {
            authService.usernameExists(username: newUsername, completion: { (canRegister) in
                if canRegister {
                    dictToUpload.updateValue(newUsername, forKey: "username")
                } else {
                    let alert = UIAlertController(title: "Error", message: "That username is taken", preferredStyle: .alert)
                    let okAction = UIAlertAction(title: "OK", style: .default, handler: nil)
                    alert.addAction(okAction)
                    self.present(alert, animated: true, completion: nil)
                    return
                }
            })
        }
        
        if !newDisplayName.isEmpty {
            dictToUpload.updateValue(newDisplayName, forKey: "fullName")
        }
        
        if !newWebsite.isEmpty {
            let websitee = newWebsite as NSString
            let validatedWebsite = validateUrl(urlString: websitee)
            
            if validatedWebsite {
                dictToUpload.updateValue(newWebsite, forKey: "website")
            } else {
                let alert = UIAlertController(title: "Error", message: "That is not a valid website", preferredStyle: .alert)
                let okAction = UIAlertAction(title: "OK", style: .default, handler: nil)
                alert.addAction(okAction)
                self.present(alert, animated: true, completion: nil)
                return
            }
        }
        
        if !newBiography.isEmpty {
            dictToUpload.updateValue(newBiography, forKey: "biograph")
        }
        
        if !newEmail.isEmpty {
            let emailValidated = validateEmail(enteredEmail: newEmail)
            
            if emailValidated {
                authService.reupdateEmail(user: self.user, email: newEmail, completion: { (status) in
                    if let error = status as? NSError {
                        if error.code == 17014 {
                            print("User Needs to reauthenticate")
                        } else {
                            print("Error: Error: \(error.localizedDescription)")
                            let alert = UIAlertController(title: "Error", message: "Please Try Again", preferredStyle: .alert)
                            let okAction = UIAlertAction(title: "OK", style: .default, handler: nil)
                            alert.addAction(okAction)
                            self.present(alert, animated: true, completion: nil)
                        }
                    } else if let reference = status as? FIRDatabaseReference {
                        print(reference)
                    } else if let canUpdate = status as? Bool {
                        print(canUpdate)
                    }
                })
            } else {
                let alert = UIAlertController(title: "Error", message: "Please enter a correctly formatted email", preferredStyle: .alert)
                let okAction = UIAlertAction(title: "OK", style: .default, handler: nil)
                alert.addAction(okAction)
                self.present(alert, animated: true, completion: nil)
                return
            }
        }
        
        if !newPhoneNumber.isEmpty {
            let numberRange = newPhoneNumber.range(of: "+44")
            var characterRangeCorrect = false
            
            if numberRange != nil, newPhoneNumber.characters.count == 14 {
                characterRangeCorrect = true
            }
            
            if newPhoneNumber.characters.count == 11 || characterRangeCorrect {
                dictToUpload.updateValue(newPhoneNumber, forKey: "phoneNumber")
            }
        }
        
        authService.saveAdditionalUserInfo(userInfo: dictToUpload, path: "Users/\(user.uid)") { (error, reference) in
            if error == nil {
                print(reference)
                self.dismiss(animated: true, completion: nil)
            } else {
                print(error?.localizedDescription)
            }
        }
        
    }
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let greyishBG = UIColor(red: 250/255.0, green: 250/255.0, blue: 250/255.0, alpha: 1.0)
        self.view.backgroundColor = greyishBG
        
        setupFields()
    }
    
    func setupFields() {
        authService.captureUser(user: self.user) { (user) in
            self.usernameField.text = user.username!
            self.username = user.username!
            let email = user.email
            
            if user.phoneNumberEmail == nil {
                self.emailField.text = email!
            }
            
            if let displayName = user.name {
                self.displayNameField.text = displayName
            }
            
            if let website = user.website {
                self.websiteField.text = website
            }
            
            if let bio = user.biograph {
                self.biographyField.text = bio
            }
            
            if let phoneNumber = user.phoneNumber {
                self.phoneNumberField.text = phoneNumber
            }
            
            if let gender = user.gender {
                self.genderField.text = gender
            } else {
                self.genderField.text = "Not Specified"
            }
            
            if let photoURL = user.photoURL {
                self.authService.retrieveProfilePicture(pictureURL: photoURL, completion: { (image) in
                    let imageView = self.tableView.viewWithTag(1996) as! UIImageView
                    DispatchQueue.main.async {
                        imageView.image = image
                    }
                })
            }
        }
    }
    
    func validateEmail(enteredEmail:String) -> Bool {
        let emailFormat = "[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,64}"
        let emailPredicate = NSPredicate(format:"SELF MATCHES %@", emailFormat)
        return emailPredicate.evaluate(with: enteredEmail)
    }
    
    func validateUrl (urlString: NSString) -> Bool {
        let urlRegEx = "((?:http|https)://)?(?:www\\.)?[\\w\\d\\-_]+\\.\\w{2,3}(\\.\\w{2})?(/(?<=/)(?:[\\w\\d\\-./_]+)?)?"
        return NSPredicate(format: "SELF MATCHES %@", urlRegEx).evaluate(with: urlString)
    }
    
    override func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        if section == 0 {
            let headerView = UIView(frame: CGRect(x: 0, y: 0, width: self.view.frame.width, height: 120))
            print(headerView.bounds)
            headerView.backgroundColor = UIColor.clear
            
            let profilePicture = #imageLiteral(resourceName: "user-placeholder.jpg")
            let imageView = UIImageView(frame: CGRect(x: 0, y: 0, width: 65, height: 65))
            imageView.image = profilePicture
            imageView.center = CGPoint(x: headerView.frame.size.width/2, y: headerView.frame.size.height/2)
            imageView.layer.masksToBounds = true
            imageView.layer.cornerRadius = imageView.frame.width / 2
            imageView.tag = 1996
            imageView.isUserInteractionEnabled = true
            let tapGesture = UITapGestureRecognizer(target: self, action: #selector(EditProfileViewController.showPhotoMenu))
            tapGesture.numberOfTapsRequired = 1
            imageView.addGestureRecognizer(tapGesture)
            
            headerView.addSubview(imageView)
            
            let changePictureButton = UIButton()
            changePictureButton.setTitle("Change Profile Photo", for: .normal)
            changePictureButton.setTitleColor(UIColor.blue, for: .normal)
            changePictureButton.setTitleColor(UIColor.red, for: .highlighted)
            changePictureButton.titleLabel?.font = UIFont.systemFont(ofSize: 12.0, weight: 0.2)
            changePictureButton.sizeToFit()
            changePictureButton.center = CGPoint(x: headerView.frame.size.width/2, y: headerView.frame.size.height / 2 + imageView.frame.size.height / 2 + 12)
            changePictureButton.addTarget(self, action: #selector(EditProfileViewController.showPhotoMenu), for: .touchUpInside)
            
            headerView.addSubview(changePictureButton)
            
            return headerView
        } else {
            return nil
        }
    }
    
    override func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        if section == 0 {
            return 120
        } else {
            return 0
        }
    }
    
    func show(image: UIImage) {
        let imageView = self.tableView.viewWithTag(1996) as! UIImageView
        imageView.image = image
    }
    
}

extension EditProfileViewController: UIImagePickerControllerDelegate, UINavigationControllerDelegate {
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


