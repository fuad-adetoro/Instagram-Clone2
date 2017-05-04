//
//  ForgotPasswordViewController.swift
//  Instagram Clone
//
//  Created by Fuad on 26/03/2017.
//  Copyright © 2017 FuadAdetoro. All rights reserved.
//

import UIKit
import Firebase

class ForgotPasswordViewController: UIViewController {

    @IBOutlet weak var usernameField: UITextField!
    @IBOutlet weak var textForSegment: UILabel!
    @IBOutlet weak var segmentedControl: UISegmentedControl!
    
    @IBAction func segmentChanged(_ sender: Any) {
        print("Change: \(segmentedControl.selectedSegmentIndex)")
        
        updateEmailField()
    }
    
    
    @IBAction func loginAction(_ sender: Any) {
        self.navigationController?.popToRootViewController(animated: true)
    }
    
    let authService = AuthService()
    
    @IBAction func sendEmailAction(_ sender: Any) {
        
        let username = usernameField.text!
        let canConvert = username.canConvertToInt
        
        if username.range(of: "@") != nil && !username.isEmpty {
            let canProceed = validateEmail(enteredEmail: usernameField.text!)
            
            if canProceed {
                authService.resetPassword(email: username, completion: { (error) in
                    if let error = error as? NSError {
                        var message = "\(error.localizedDescription) \(error.code)"
                        if error.code == 17011 {
                            message = "That account doesn't exist!"
                        }
                        
                        UIView.animate(withDuration: 3, animations: { 
                            self.displayErrorView(error: message, textColor: UIColor.red, viewBG: UIColor.white, fontSize: 14.0)
                        }, completion: { _ in
                            self.removeErrorView()
                        })
                    } else {
                        self.presentAlert(title: "Success", message: "A password reminder has been sent.", myHandler: { (_) in
                            self.navigationController?.popToRootViewController(animated: true)
                        })
                    }
                })
            } else {
                self.presentAlert(title: "Error", message: "Please enter a valid email address.", myHandler: nil)
            }
        } else if canConvert != nil {
            var phoneNumberUsername = username
            let characterRange = phoneNumberUsername.range(of: "+44")
            let characterLength = phoneNumberUsername.characters.count
            
            if characterRange != nil || characterLength == 10 {
                if characterRange != nil {
                    phoneNumberUsername = username.replacingOccurrences(of: "+44", with: "0")
                } else {
                    phoneNumberUsername = "0\(username)"
                }
                
                authService.resetPasswordWithPhoneNumber(phoneNumber: phoneNumberUsername, completion: { (status, phoneNumberEmail) in
                    if let error = status as? NSError {
                        print("\(error.localizedDescription) \(error.code)")
                        UIView.animate(withDuration: 3, animations: {
                            self.displayErrorView(error: "User not found", textColor: UIColor.red, viewBG: UIColor.white, fontSize: 14.0)
                        }, completion: { _ in
                            self.removeErrorView()
                        })
                    } else if let status = status as? Bool, status == false {
                        self.createAccountError()
                    } else {
                        if phoneNumberEmail != nil {
                            self.presentAlert(title: "Error", message: "You don't have an email address, we will contact you!", myHandler: nil)
                        } else {
                            self.presentAlert(title: "Success", message: "A password reminder has been sent.", myHandler: { (_) in
                            self.navigationController?.popToRootViewController(animated: true)
                            })
                        }
                    }
                })
            } else {
                self.presentAlert(title: "Error", message: "Phone Number Is Incorrectly Formatted!", myHandler: nil)
            }
        } else if !usernameField.text!.isEmpty {
            authService.resetPasswordWithUsername(username: username, completion: { (error) in
                if let error = error as? NSError {
                    print("\(error.localizedDescription) \(error.code)")
                    UIView.animate(withDuration: 3, animations: {
                        self.displayErrorView(error: "User not found", textColor: UIColor.red, viewBG: UIColor.white, fontSize: 14.0)
                    }, completion: { _ in
                        self.removeErrorView()
                    })
                } else {
                    self.presentAlert(title: "Success", message: "A password reminder has been sent.", myHandler: { (_) in
                        self.navigationController?.popToRootViewController(animated: true)
                    })
                }
            })
        } else {
            self.presentAlert(title: "Error", message: "Please fill in the field.", myHandler: nil)
        }
        
    }
    
    @IBOutlet weak var sendEmail: UIButton!
    
    override func viewDidLoad() {
        super.viewDidLoad()

        let bgColor = UIColor(red: 178/255.0, green: 85/255.0, blue: 157/255.0, alpha: 1).cgColor
        
        sendEmail.layer.borderColor = bgColor
        sendEmail.layer.borderWidth = CGFloat(2.0)
        sendEmail.layer.cornerRadius = CGFloat(5.0)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        UIApplication.shared.isStatusBarHidden = true
    }
    
    override var prefersStatusBarHidden: Bool {
        return true
    }
    
    func displayErrorView(error: String, textColor: UIColor, viewBG: UIColor, fontSize: CGFloat) {
        let errorView = UIView(frame: CGRect(x: 0, y: 0, width: self.view.frame.width, height: 45))
        errorView.backgroundColor = viewBG
        errorView.tag = 165
        self.view.addSubview(errorView)
        
        let label = UILabel(frame: CGRect(x: 0, y: 0, width: 0, height: 0))
        label.text = "\(error)"
        label.textColor = textColor
        label.textAlignment = .center
        label.numberOfLines = 1
        label.font = UIFont(name: "Verdana", size: fontSize)
        label.sizeToFit()
        label.center = CGPoint(x: errorView.frame.width/2, y: errorView.frame.height/2)
        label.tag = 156
        
        errorView.addSubview(label)
    }
    
    func removeErrorView() {
        let errorView = self.view.viewWithTag(165)
        errorView?.removeFromSuperview()
        
        let label = self.view.viewWithTag(156)
        label?.removeFromSuperview()
    }
    
    func validateEmail(enteredEmail:String) -> Bool {
        let emailFormat = "[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,64}"
        let emailPredicate = NSPredicate(format:"SELF MATCHES %@", emailFormat)
        return emailPredicate.evaluate(with: enteredEmail)
    }
    
    func presentAlert(title: String, message: String, myHandler: ((UIAlertAction) -> Void)?) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        let okAction = UIAlertAction(title: "OK", style: .default, handler: myHandler)
        alert.addAction(okAction)
        present(alert, animated: true, completion: nil)
    }
    
    func updateEmailField() {
        if segmentedControl.selectedSegmentIndex == 1 {
            usernameField.placeholder = "Phone"
            
            setupTextFieldButton()
            
            usernameField.keyboardType = .numberPad
            
            let text = "Enter your phone number and we'll send you a password reset link to get back into your account."
            updateDescription(with: text)
            
        } else {
            usernameField.setLeftPaddingPoints(0)
            usernameField.placeholder = "Username or email address"
            usernameField.keyboardType = .emailAddress
            
            removeView(with: 90210)
            
            let text = "Enter your username or email address and we'll send you a link to get back into your account."
            updateDescription(with: text)
        }
    }
    
    func setupTextFieldButton() {
        let button = UIButton(frame: CGRect(x: 0, y: 0, width: usernameField.frame.width/4, height: usernameField.frame.height))
        button.backgroundColor = UIColor.clear
        button.setTitle("GB +44", for: .normal)
        button.tag = 90210
        button.setTitleColor(UIColor.white, for: .normal)
        button.titleLabel!.font = UIFont.boldSystemFont(ofSize: 14.0)
        
        self.usernameField.addSubview(button)
        self.usernameField.setLeftPaddingPoints(button.frame.size.width)
        
    }
    
    func removeView(with tag: Int) {
        if let view = usernameField.viewWithTag(tag) {
            view.removeFromSuperview()
        }
    }
    
    func updateDescription(with text: String) {
        self.textForSegment.text = text
    }
    
    func createAccountError() {
        let alert = UIAlertController(title: "That Account Doesn't Exist!", message: "If you have an account try again or Get started and create a new account.", preferredStyle: .alert)
        let tryAgainAction = UIAlertAction(title: "Try Again", style: .default, handler: nil)
        let getStartedAction = UIAlertAction(title: "Get Started?", style: .default) { (alert) in
            self.performSegue(withIdentifier: "UserSignUp", sender: nil)
        }
        
        alert.addAction(tryAgainAction)
        alert.addAction(getStartedAction)
        
        self.present(alert, animated: true, completion: nil)
    }
}

extension ForgotPasswordViewController: UITextFieldDelegate {
    func textFieldDidBeginEditing(_ textField: UITextField) {
        textField.clearButtonMode = .whileEditing
    }
}
