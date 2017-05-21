//
//  FirstSignUpViewController.swift
//  Instagram Clone
//
//  Created by Fuad on 25/03/2017.
//  Copyright © 2017 FuadAdetoro. All rights reserved.
////

import UIKit

class FirstSignUpViewController: UIViewController {

    @IBAction func signInAction(_ sender: Any) {
        self.navigationController?.popToRootViewController(animated: true)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.navigationController?.isNavigationBarHidden = true
    }
}

extension FirstSignUpViewController: UITextFieldDelegate {
    func textFieldDidBeginEditing(_ textField: UITextField) {
        textField.clearButtonMode = .whileEditing
    }
}
