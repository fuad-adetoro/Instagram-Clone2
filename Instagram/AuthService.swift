//
//  AuthService.swift
//  Instagram Clone
//
//  Created by Fuad on 25/03/2017.
//  Copyright © 2017 FuadAdetoro. All rights reserved.
//

import UIKit
import Firebase

typealias SignUpCompletion = (User?, Error?) -> Void
typealias Completion = (Any) -> Void
typealias BoolCompletion = (Bool) -> Void
typealias ResetCompletion = (Any, Bool?) -> Void
typealias AccountExists = (User) -> Void

struct AuthService {
    
    var databaseRef: DatabaseReference {
        return Database.database().reference()
    }
    
    var storageRef: StorageReference {
        return Storage.storage().reference()
    }
    
    func logUserIn(email: String, password: String, completion: @escaping Completion) {
        Auth.auth().signIn(withEmail: email, password: password, completion: { (user, error) in
            if let error = error as NSError! {
                completion(error)
            } else {
                print(user!)
                
                let appDel: AppDelegate = UIApplication.shared.delegate as! AppDelegate
                appDel.logUser()
            }
        })
    }
    
    func resetPassword(email: String, completion: @escaping Completion) {
        Auth.auth().sendPasswordReset(withEmail: email, completion: completion)
    }
    
    func signUserUp(email: String, password: String, username: String, completion: @escaping SignUpCompletion) {
        Auth.auth().createUser(withEmail: email, password: password, completion: completion)
    }
    
    func saveUserInfo(user: User, email: String, username: String, phoneNumber: String?) {
        // userInfo is the data that we will create and upload to the userData
        var userInfo: [String: Any] = [:]
        
        if let phoneNumber = phoneNumber {
            userInfo = ["userID": user.uid, "email": email.lowercased(), "username": username.lowercased(), "phoneNumber": phoneNumber, "phoneNumberEmail": true]
        } else {
            userInfo = ["userID": user.uid, "email": email.lowercased(), "username": username.lowercased()]
        }
        
        let userData = databaseRef.child("Users/").child(user.uid)
        
        userData.setValue(userInfo) { (error, reference) in
            if error == nil {
                // Updating the FIRUser's firebase display name
                let changeRequest = user.createProfileChangeRequest()
                changeRequest.displayName = username
                print("User Details Saved Successfully!")
            } else {
                print("Error From Auth Service: \(error!)")
            }
        }
    }
    
    func updateProfilePhoto(user: User, picture: UIImage) {
        print("updateProfilePhoto")
        let data = UIImageJPEGRepresentation(picture, 5 * 1024 * 1024)! as NSData
        
        // Profile Picture Reference
        let imageRef = storageRef.child("ProfileImages/").child(user.uid).child("profile_picture.jpg")
        
        let metaData = StorageMetadata()
        metaData.contentType = "image/jpeg"
        
        // Updating the user's profile picture
        imageRef.putData(data as Data, metadata: metaData) { (newMetaData, error) in
            if error == nil {
                let changeRequest = user.createProfileChangeRequest()
                
                if let photoURL = newMetaData!.downloadURL() {
                    changeRequest.photoURL = photoURL
                }
                
                changeRequest.commitChanges(completion: { (error) in
                    if error == nil {
                        self.saveAdditionalUserInfo(path: "Users/\(user.uid)/", key: "photoURL", value: String(describing: changeRequest.photoURL!))
                    } else {
                        print(error?.localizedDescription)
                    }
                })
            } else {
                print(error?.localizedDescription)
            }
        }
    }
    
    func saveAdditionalUserInfo(path: String, key: String, value: Any) {
        let userInfo = ["\(key)": "\(value)"]
        
        databaseRef.child(path).updateChildValues(userInfo) { (error, reference) in
            if error == nil {
                print("User Updated Successfully \(reference)")
            } else {
                print("User update failed \(error?.localizedDescription)")
            }
        }
    }
    
    typealias SaveCompletion = (Error?, DatabaseReference) -> Void
    
    func saveAdditionalUserInfo(userInfo: [String: Any], path: String, completion: @escaping SaveCompletion) {
        
        databaseRef.child("\(path)").updateChildValues(userInfo, withCompletionBlock: completion)
    }
    
    func reupdateEmail(user: User, email: String, completion: @escaping UpdateEmail) {
        // new email dict
        let emailUserInfo = ["email": email.lowercased()]
        
        let userData = databaseRef.child("Users/\(user.uid)")
        
        // check if the email exists, proceed if it doesn't§
        self.emailExists(email: email) { (canUpdate) in
            
            // If email doesn't exist canUpdate
            if canUpdate {
                user.updateEmail(to: email, completion: { (error) in
                    if let error = error as? NSError {
                        if error.code == 17014 {
                            print("User needs to reauthenticate")
                            completion(error)
                        } else {
                            print("\(error.localizedDescription) \(error.code)")
                            completion(error)
                        }
                    } else {
                        userData.updateChildValues(emailUserInfo, withCompletionBlock: { (error, reference) in
                            if let error = error as? NSError {
                                print(error.localizedDescription)
                                completion(error)
                            } else {
                                
                                let userPhoneEmailData = userData.child("PhoneNumberEmail")
                                userPhoneEmailData.removeValue()
                                completion(reference)
                            }
                        })
                    }
                })
            } else {
                print("Can't Update")
                completion(canUpdate)
            }
        }
    }
    
    
    typealias UpdateEmail = (Any) -> Void
    
    func updateEmail(user: User, email: String, completion: @escaping UpdateEmail) {
        
        let userInfo = ["email": email.lowercased()]
        
        let userData = databaseRef.child("Users/\(user.uid)/")
        
        self.emailExists(email: email) { (canUpdate) in
            if canUpdate {
                userData.updateChildValues(userInfo, withCompletionBlock: { (error, reference) in
                    if error == nil {
                        userData.child("phoneNumberEmail").removeValue()
                        
                        user.updateEmail(to: email, completion: { (error) in
                            if error == nil {
                                print("Email successfully updated!")
                            } else {
                                if let error = error as? NSError {
                                    print("\(error.localizedDescription) \(error.code)")
                                }
                            }
                        })
                        
                        print(reference)
                        completion(reference)
                    } else {
                        print(error?.localizedDescription)
                        completion(error)
                    }
                })
            } else {
                print("Can't Register!")
                completion(canUpdate)
            }
        }
    }
    
    func emailExists(email: String, completion: @escaping BoolCompletion) {
        var canRegister = false
        
        Auth.auth().signIn(withEmail: email, password: " ", completion: { (user, error) in
            if let error = error as? NSError {
                if error.code == 17009 {
                    canRegister = false
                } else if error.code == 17011 {
                    canRegister = true
                }
            }
            
            completion(canRegister)
        })
    }
    
    func usernameExists(username: String, completion: @escaping BoolCompletion) {
        var canRegister = true
        print("Right Here!")
        databaseRef.child("Users/").observeSingleEvent(of: .value, with: { (snapshot) in
            if snapshot.exists() {
                for child in snapshot.children {
                    let profile = Profile(snapshot: child as! DataSnapshot)
                
                    if canRegister == true {
                        if profile.username! == username {
                            canRegister = false
                        } else {
                            canRegister = true
                        }
                    } else {
                        completion(canRegister)
                    }
                }
            }
            
            completion(canRegister)
        })
    }
    
    func phoneNumberExists(phoneNumber: String, completion: @escaping BoolCompletion) {
        var canRegister = true
        
        databaseRef.child("Users/").observeSingleEvent(of: .value, with: { snapshot in
            if snapshot.exists() {
                for child in snapshot.children {
                    let profile = Profile(snapshot: child as! DataSnapshot)
                    
                    if profile.phoneNumber == "0\(phoneNumber)" {
                        canRegister = false
                        completion(canRegister)
                        return
                    }
                }
            }
            
            if canRegister {
                completion(canRegister)
            }
        })
    }
    
    func signInWithUsername(username: String, password: String, completion: @escaping Completion) {
        databaseRef.child("Users/").observeSingleEvent(of: .value, with: { snapshot in
            
            var accountFound = false
            
            for children in snapshot.children {
                let profile = Profile(snapshot: children as! DataSnapshot)
                
                if username == profile.username! {
                    let email = profile.email
                    
                    accountFound = true
                    
                    self.logUserIn(email: email!, password: password, completion: { (error) in
                        if let error = error as? NSError {
                            completion(error)
                            return
                        } else {
                            completion(true)
                            return
                        }
                    })
                }
            }
            
            if !accountFound {
                completion(false)
            }
        })
    }
    
    func signInWithPhoneNumber(phoneNumber: String, password: String, completion: @escaping Completion) {
        databaseRef.child("Users/").observeSingleEvent(of: .value, with: { snapshot in
            var accountFound = false
            
            for children in snapshot.children {
                let profile = Profile(snapshot: children as! DataSnapshot)
                
                if phoneNumber == profile.phoneNumber {
                    accountFound = true
                    let email = profile.email!
                    
                    self.logUserIn(email: email, password: password, completion: { (error) in
                        if let error = error as? NSError {
                            completion(error)
                            return
                        } else {
                            if let phoneNumberEmail = profile.phoneNumberEmail {
                                completion(true)
                                return
                            } else {
                                completion(true)
                            }
                        }
                    })
                }
            }
            
            if !accountFound {
                completion(false)
            }
        })
        
    }
    
    func createAccountWithPhoneNumber(phoneNumber: String, password: String, completion: @escaping SignUpCompletion) {
        Auth.auth().createUser(withEmail: "\(phoneNumber)@instagram.com", password: password, completion: completion)
    }
    
    
    
    // MARK: - Forgotten Password!
    func resetPasswordWithUsername(username: String, completion: @escaping Completion) {
        databaseRef.child("Users/").observeSingleEvent(of: .value, with: { snapshot in
            for children in snapshot.children {
                let profile = Profile(snapshot: children as! DataSnapshot)
                
                if username == profile.username! {
                    let email = profile.email!
                    
                    Auth.auth().sendPasswordReset(withEmail: email, completion: { (error) in
                        if let error = error as? NSError {
                            completion(error)
                        } else {
                            completion(true)
                            print("Forgot password link sent.")
                        }
                    })
                }
            }
        })
    }
    
    func resetPasswordWithPhoneNumber(phoneNumber: String, completion: @escaping ResetCompletion) {
        databaseRef.child("Users/").observeSingleEvent(of: .value, with: { snapshot in
            var accountFound = false
            
            for children in snapshot.children {
                let profile = Profile(snapshot: children as! DataSnapshot)
                
                if let number = profile.phoneNumber, phoneNumber == number {
                    accountFound = true
                    let email = profile.email!
                    
                    Auth.auth().sendPasswordReset(withEmail: email, completion: { (error) in
                        if let error = error as? NSError {
                            completion(error, nil)
                        } else {
                            
                            if let phoneNumberEmail = profile.phoneNumberEmail {
                                completion(true, phoneNumberEmail)
                                print("Forgot Password not sent.")
                            } else {
                                completion(true, nil)
                                print("Forgot password link sent.")
                            }
                        }
                        
                        return
                    })
                }
            }
            
            if !accountFound {
                completion(accountFound, nil)
            }
        })
    }
    
    typealias CapturedUser = (Profile) -> Void
    
    func captureUser(user: User, completion: @escaping CapturedUser) {
        let userData = databaseRef.child("Users/\(user.uid)/")
        
        userData.observeSingleEvent(of: .value, with: { snapshot in
            let profile = Profile(snapshot: snapshot)
            completion(profile)
        })
    }
    
    typealias ImageReceived = (UIImage) -> Void
    
    func retrieveProfilePicture(pictureURL: String, completion: @escaping ImageReceived) {
        var newStorageRef: Storage {
            return Storage.storage()
        }
        
        newStorageRef.reference(forURL: pictureURL).getData(maxSize: 5 * 1024 * 1024) { (imgData, error) in
            if error == nil {
                if imgData != nil, let image = UIImage(data: imgData!) {
                    DispatchQueue.main.async {
                        completion(image)
                    }
                }
            } else {
                print(error?.localizedDescription)
            }
        }
    }
    
    typealias ProfileFound = (Profile) -> Void
    
    func fetchUser(user: User, completion: @escaping ProfileFound) {
        let userData = databaseRef.child("Users/\(user.uid)")
        userData.observeSingleEvent(of: .value, with: { snapshot in
            let capturedProfile = Profile(snapshot: snapshot)
            completion(capturedProfile)
        })
    }
    
    func userFromId(id: String, completion: @escaping ProfileFound) {
        let userData = databaseRef.child("Users/\(id)/")
        
        userData.observeSingleEvent(of: .value, with: { snapshot in
            let capturedProfile = Profile(snapshot: snapshot)
            completion(capturedProfile)
        })
    }
    
    typealias UserLogout = (Any) -> Void
    
    func logUserOut(currentUser: User?, completion: @escaping UserLogout) {
        if currentUser != nil {
            do {
                try? Auth.auth().signOut()
                completion(true)
            } catch let error {
                print("Error logging out! \(error)")
                completion(error)
            }
        }
    }
    
}
