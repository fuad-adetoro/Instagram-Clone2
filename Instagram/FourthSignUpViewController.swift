//
//  FourthSignUpViewController.swift
//  Instagram Clone
//
//  Created by Fuad on 25/03/2017.
//  Copyright © 2017 FuadAdetoro. All rights reserved.
////

import UIKit
import Firebase

class FourthSignUpViewController: UIViewController {

    @IBOutlet weak var usernameField: UITextField!
    
    var email: String!
    var password: String!
    var fullName: String?
    var profilePicture: UIImage?
    var phoneNumber: String?
    let authService = AuthService()
    
    @IBAction func signIn(_ sender: Any) {
        self.navigationController?.popToRootViewController(animated: true)
    }
    
    @IBAction func nextAction(_ sender: Any) {
        
        let username = usernameField.text!
        
        print("Email Address: \(self.email!)")
        print("username \(username.lowercased())")
        
        authService.usernameExists(username: username.lowercased()) { (bool) in
            if bool {
                self.authService.signUserUp(email: self.email, password: self.password, username: self.usernameField.text!) { (user, error) in
                    if error != nil {
                        print("\(error?.localizedDescription)")
                    } else {
                        if let user = user {
                            self.authService.saveUserInfo(user: user, email: self.email, username: self.usernameField.text!, phoneNumber: nil)
                            
                            if let fullName = self.fullName {
                                self.authService.saveAdditionalUserInfo(path: "Users/\(user.uid)/", key: "fullName", value: "\(fullName)")
                            }
                            
                            if let picture = self.profilePicture {
                                self.authService.updateProfilePhoto(user: user, picture: picture)
                            } else {
                                let placeholderPicture = #imageLiteral(resourceName: "user-placeholder.jpg")
                                self.authService.updateProfilePhoto(user: user, picture: placeholderPicture)
                            }
                            
                            if let phoneNumber = self.phoneNumber {
                                let userInfo: [String: Any] = ["phoneNumber": phoneNumber, "phoneNumberEmail": true]
                                
                                self.authService.saveAdditionalUserInfo(userInfo: userInfo, path: "Users/\(user.uid)", completion: { (error, reference) in
                                    if error == nil {
                                        print(reference)
                                    } else {
                                        print(error?.localizedDescription)
                                    }
                                })
                            }
                            
                            let appDel: AppDelegate = UIApplication.shared.delegate as! AppDelegate
                            appDel.logUser()
                        }
                    }
                }
            } else {
                let alert = UIAlertController(title: "Error", message: "That username is taken", preferredStyle: .alert)
                let okAction = UIAlertAction(title: "OK", style: .default, handler: nil)
                alert.addAction(okAction)
                self.present(alert, animated: true, completion: nil)
            }
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()

    }
}

extension FourthSignUpViewController: UITextFieldDelegate {
    func textFieldDidBeginEditing(_ textField: UITextField) {
        textField.clearButtonMode = .whileEditing
    }
}
