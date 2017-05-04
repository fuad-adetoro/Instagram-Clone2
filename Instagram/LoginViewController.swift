//
//  ViewController.swift
//  Instagram Clone
//
//  Created by Fuad on 24/03/2017.
//  Copyright © 2017 FuadAdetoro. All rights reserved.
//

import UIKit
import Firebase

class LoginViewController: UIViewController {
    
    @IBOutlet weak var usernameField: UITextField!
    @IBOutlet weak var passwordField: UITextField!
    
    let authService = AuthService()
    
    @IBAction func textFieldChanged(_ sender: Any) {
        if !usernameField.text!.isEmpty && !passwordField.text!.isEmpty {
            loginOutlet.isEnabled = true
        } else {
            loginOutlet.isEnabled = false
        }
    }
    
    @IBOutlet weak var loginOutlet: UIButton!
    @IBAction func loginAction(_ sender: Any) {
        
        var username = usernameField.text!
        let password = passwordField.text!
        let canConvert = username.canConvertToInt
        let emailAddressRange = username.range(of: "@")
        
        if emailAddressRange != nil {
            
            authService.logUserIn(email: username, password: password, completion: { (error) in
                if let error = error as? NSError {
                    if error.code == 17009 || error.code == 17010 {
                        self.forgotPasswordError()
                    } else {
                        print("Error Description \(error.description), Error Code \(error.code), ")
                        self.createAccountError()
                    }
                } else {
                    self.loginOutlet.setTitle("", for: .normal)
                    self.loginOutlet.setupLoaderButton()
                }
            })
        } else if canConvert != nil {
            let characterRange = username.range(of: "+44")
            let characterLength = username.characters.count
        
            if characterLength == 11 || characterRange != nil {
                
                if characterRange != nil {
                    username = usernameField.text!.replacingOccurrences(of: "+44", with: "0")
                }
                
                authService.signInWithPhoneNumber(phoneNumber: username, password: passwordField.text!, completion: { (status) in
                    if let error = status as? NSError {
                        self.forgotPasswordError()
                    } else if let status = status as? Bool, status == false {
                        self.createAccountError()
                    } else {
                        self.loginOutlet.setTitle("", for: .normal)
                        self.loginOutlet.setupLoaderButton()
                    }
                })
            } else {
                let alert = UIAlertController(title: "Error", message: "Phone Number Is Incorrectly Formatted!", preferredStyle: .alert)
                let okAction = UIAlertAction(title: "OK", style: .default, handler: nil)
                alert.addAction(okAction)
                present(alert, animated: true, completion: nil)
            }
        } else {
            authService.signInWithUsername(username: usernameField.text!, password: passwordField.text!, completion: { (status) in
                if let error = status as? NSError {
                    self.forgotPasswordError()
                } else if let status = status as? Bool, status == false {
                    self.createAccountError()
                } else {
                    self.loginOutlet.setTitle("", for: .normal)
                    self.loginOutlet.setupLoaderButton()
                }
            })
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.navigationController?.isNavigationBarHidden = true
    }
    
    func createAccountError() {
        let alert = UIAlertController(title: "Trouble Logging In?", message: "If you have an account try again or Get started and create a new account.", preferredStyle: .alert)
        let tryAgainAction = UIAlertAction(title: "Try Again", style: .default, handler: nil)
        let getStartedAction = UIAlertAction(title: "Get Started?", style: .default) { (alert) in
            self.performSegue(withIdentifier: "UserSignUp", sender: nil)
        }
        
        alert.addAction(tryAgainAction)
        alert.addAction(getStartedAction)
        
        self.present(alert, animated: true, completion: nil)
    }
    
    func forgotPasswordError() {
        let alert = UIAlertController(title: "Forgotten password", message: "If you've forgotten your username or password, we can help you get back into your account.", preferredStyle: .alert)
        let tryAgainAction = UIAlertAction(title: "Try Again", style: .default, handler: nil)
        let forgotPasswordAction = UIAlertAction(title: "Forgotten Password?", style: .default) { (alert) in
            self.performSegue(withIdentifier: "UserForgottenPassword", sender: nil)
        }
        
        alert.addAction(tryAgainAction)
        alert.addAction(forgotPasswordAction)
        
        self.present(alert, animated: true, completion: nil)
    }
}

extension LoginViewController: UITextFieldDelegate {
    func textFieldDidBeginEditing(_ textField: UITextField) {
        textField.clearButtonMode = .whileEditing
    }
}

