//
//  SecondSignUpViewController.swift
//  Instagram Clone
//
//  Created by Fuad on 25/03/2017.
//  Copyright © 2017 FuadAdetoro. All rights reserved.
//

import UIKit
import Firebase

class SecondSignUpViewController: UIViewController {

    @IBOutlet weak var segmentedControl: UISegmentedControl!
    @IBOutlet weak var emailAddress: UITextField!
    @IBOutlet weak var gbButton: UIButton!
    
    
    let authService = AuthService()
    
    @IBAction func segmentedControlChange(_ sender: Any) {
        updateEmailField()
    }
    
    @IBAction func nextAction(_ sender: Any) {
        
        if self.segmentedControl.selectedSegmentIndex == 0 {
            let number = emailAddress.text!
            
            if number.characters.count != 10 {
                presentAlert(title: "Error", message: "Please Enter A Correct GB Phone Number.", myHandler: nil)
            } else {
                authService.phoneNumberExists(phoneNumber: number, completion: { (canRegister) in
                    if canRegister {
                        let email = "0\(number)@instagram.com"
                        
                        print("\(email)")
                        
                        self.performSegue(withIdentifier: "CreateAccountStepOne", sender: email)
                    } else {
                        self.presentAlert(title: "Error", message: "That Phone Number Is Taken!", myHandler: nil)
                    }
                })
            }
        } else {
            let canProceed = validateEmail(enteredEmail: emailAddress.text!)
            if canProceed {
                print("True")
                let email = emailAddress.text!
                if !email.isEmpty {
                    
                    authService.emailExists(email: email, completion: { (canRegister) in
                        if canRegister {
                            self.performSegue(withIdentifier: "CreateAccountStepOne", sender: email)
                        } else {
                            self.presentAlert(title: "Error", message: "That Phone Number Is Taken!", myHandler: nil)
                        }
                    })
                }
            } else {
                self.presentAlert(title: "Error", message: "Please enter a valid email address.", myHandler: nil)
            }
        }
    }
    
    @IBAction func signInAction(_ sender: Any) {
        self.navigationController?.popToRootViewController(animated: true)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        updateEmailField()
    }

    func updateEmailField() {
        if segmentedControl.selectedSegmentIndex == 0 {
            emailAddress.text = ""
            emailAddress.placeholder = "Phone Number"
            emailAddress.keyboardType = .numberPad
            setupTextFieldButton()
        } else {
            emailAddress.text = ""
            emailAddress.setLeftPaddingPoints(0)
            emailAddress.placeholder = "Email Address"
            emailAddress.keyboardType = .emailAddress
            
            removeView(with: 90211)
        }
    }
    
    func setupTextFieldButton() {
        let button = UIButton(frame: CGRect(x: 0, y: 0, width: emailAddress.frame.width/4, height: emailAddress.frame.height))
        button.backgroundColor = UIColor.clear
        button.setTitle("GB +44", for: .normal)
        button.tag = 90211
        button.setTitleColor(UIColor.blue, for: .normal)
        button.titleLabel!.font = UIFont.boldSystemFont(ofSize: 14.0)
        
        self.emailAddress.addSubview(button)
        self.emailAddress.setLeftPaddingPoints(button.frame.size.width)
        
    }
    
    func removeView(with tag: Int) {
        if let view = emailAddress.viewWithTag(tag) {
            view.removeFromSuperview()
        }
    }
    
    func validateEmail(enteredEmail:String) -> Bool {
        let emailFormat = "[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,64}"
        let emailPredicate = NSPredicate(format:"SELF MATCHES %@", emailFormat)
        return emailPredicate.evaluate(with: enteredEmail)
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "CreateAccountStepOne" {
            print("segment")
            let vc = segue.destination as! ThirdSignUpViewController
            let email = sender as! String
            print(email)
            vc.email = email
            
            if segmentedControl.selectedSegmentIndex == 0 {
                vc.phoneNumber =  "0\(emailAddress.text!)"
            }
        }
    }
    
    func presentAlert(title: String, message: String, myHandler: ((UIAlertAction) -> Void)?) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        let okAction = UIAlertAction(title: "OK", style: .default, handler: myHandler)
        alert.addAction(okAction)
        present(alert, animated: true, completion: nil)
    }
}

extension SecondSignUpViewController: UITextFieldDelegate {
    func textFieldDidBeginEditing(_ textField: UITextField) {
        textField.clearButtonMode = .whileEditing
    }
}

extension UITextField {
    func setLeftPaddingPoints(_ amount:CGFloat){
        let paddingView = UIView(frame: CGRect(x: 0, y: 0, width: amount, height: self.frame.size.height))
        self.leftView = paddingView
        self.leftViewMode = .always
    }
}
