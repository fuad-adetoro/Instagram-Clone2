//
//  UserActivityViewController.swift
//  Instagram
//
//  Created by Fuad Adetoro on 23/05/2017.
//  Copyright © 2017 Instagram. All rights reserved.
//

import UIKit
import Firebase

class UserActivityViewController: UIViewController {

    let currentUser = Auth.auth().currentUser
    var profile: Profile?
    let authService = AuthService()
    let accountService = AccountService()
    var activity: [UserActivity] = []
    var downloadTask: URLSessionDownloadTask!
    
    @IBOutlet weak var tableView: UITableView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        tableView.estimatedRowHeight = 60
        tableView.rowHeight = UITableViewAutomaticDimension
        tableView.tableFooterView = UIView()
        
        let refreshControl = UIRefreshControl()
        refreshControl.tag = 60
        refreshControl.addTarget(self, action: #selector(self.fetchUser) , for: .valueChanged)
        tableView.addSubview(refreshControl)
        
        fetchUser()
    }
    
    func fetchUser() {
        authService.fetchUser(user: currentUser!) { (profile) in
            self.profile = profile
            if let refreshControl = self.view.viewWithTag(60) as? UIRefreshControl {
                refreshControl.beginRefreshing()
            }
            self.setupActivity(profile: profile)
        }
    }
    
    func setupActivity(profile: Profile) {
        let profileActivity = ProfileActivity(profile: profile)
        
        profileActivity.checkProfileActivity { (userActivity) in
            self.activity = userActivity

            if let refreshControl = self.view.viewWithTag(60) as? UIRefreshControl {
                refreshControl.endRefreshing()
            }
            
            self.tableView.reloadData()
            print("User Activity Received: \(userActivity)")
        }
    }
    
    func loadProfileWithUsername(username: String) {
        accountService.fetchUserWithUsername(username: username) { (profile) in
            let storyboard = UIStoryboard(name: "Main", bundle: nil)
            let profileVC = storyboard.instantiateViewController(withIdentifier: "ViewUserProfile") as! ViewUserProfileViewController
            profileVC.profile = profile
            self.navigationController?.pushViewController(profileVC, animated: true)
        }
    }
    
    func loadProfileWithTap(sender: UITapGestureRecognizer) {
        if let indexPath = self.tableView.indexPathForRow(at: sender.location(in: self.tableView)) {
            let userActivity = activity[indexPath.row]
            
            if let profile = userActivity.profile {
                loadProfileWithUsername(username: profile.username!)
            } else {
                print("Error locating user in activity")
            }
        }
    }
    
    func goToPost(dataDict: [String: Any]) {
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        let profilePostVC = storyboard.instantiateViewController(withIdentifier: "ShowPost") as! ViewProfilePostController
        let post = dataDict["post"] as! Post
        let profile = dataDict["profile"] as! Profile
        profilePostVC.post = post
        profilePostVC.profile = profile
        
        self.navigationController?.pushViewController(profilePostVC, animated: true)
    }
    
    func loadPostWithTap(sender: UITapGestureRecognizer) {
        if let indexPath = self.tableView.indexPathForRow(at: sender.location(in: self.tableView)) {
            let userActivity = activity[indexPath.row]
            
            if let post = userActivity.postReference {
                authService.userFromId(id: post.userID!, completion: { (profile) in
                    let dataDict: [String: Any] = ["profile": profile, "post": post]
                    self.goToPost(dataDict: dataDict)
                })
            } else {
                print("There is no post!")
            }
        }
    }
}

extension UserActivityViewController: UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return activity.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let userActivity = activity[indexPath.row]
        
        guard let profile = userActivity.profile else {
            print("There was an error.")
            return UITableViewCell()
        }
        
        switch userActivity.activityType {
        case .mentions, .likes:
            let cell = tableView.dequeueReusableCell(withIdentifier: "PostReferenceCell", for: indexPath)
            
            let profilePicture = cell.viewWithTag(1337) as! UIImageView
            let referenceTextView = cell.viewWithTag(1338) as! UITextView
            let pictureReference = cell.viewWithTag(1339) as! UIImageView
            
            profilePicture.layer.masksToBounds = true
            profilePicture.layer.cornerRadius = profilePicture.frame.width / 2
            
            let profilePictureTap = UITapGestureRecognizer(target: self, action: #selector(self.loadProfileWithTap(sender:)))
            profilePictureTap.numberOfTapsRequired = 1
            profilePicture.addGestureRecognizer(profilePictureTap)
            
            let pictureReferenceTap = UITapGestureRecognizer(target: self, action: #selector(self.loadPostWithTap(sender:)))
            pictureReferenceTap.numberOfTapsRequired = 1
            pictureReference.addGestureRecognizer(pictureReferenceTap)
            
            
            if let url = URL(string: profile.photoURL!) {
                DispatchQueue.main.async {
                    self.downloadTask = profilePicture.loadImage(url: url)
                }
            }
            
            if let post = userActivity.postReference, let photoURL = URL(string: post.imageURL!) {
                DispatchQueue.main.async {
                    self.downloadTask = pictureReference.loadImage(url: photoURL)
                }
            }
            
            
            print("Activity Type: \(userActivity.activityType)") 
            
            if case .likes = userActivity.activityType {
                referenceTextView.text = "\(profile.username!) has liked your post!"
            } else if case .mentions = userActivity.activityType {
                referenceTextView.text = "\(profile.username!) has mentioned you in a post!"
            }
            
            referenceTextView.sizeToFit()
            referenceTextView.textContainer.lineFragmentPadding = 0
            referenceTextView.textContainerInset = UIEdgeInsets.zero
            referenceTextView.delegate = self
            referenceTextView.resolveHashTags()
            
            return cell
        case .followActivity:
            let cell = tableView.dequeueReusableCell(withIdentifier: "FollowActivityCell", for: indexPath)
            
            let profilePicture = cell.viewWithTag(1447) as! UIImageView
            let referenceTextView = cell.viewWithTag(1448) as! UITextView
            
            profilePicture.layer.masksToBounds = true
            profilePicture.layer.cornerRadius = profilePicture.frame.width / 2
            
            let profilePictureTap = UITapGestureRecognizer(target: self, action: #selector(self.loadProfileWithTap(sender:)))
            profilePictureTap.numberOfTapsRequired = 1
            profilePicture.addGestureRecognizer(profilePictureTap)
            
            if let url = URL(string: profile.photoURL!) {
                DispatchQueue.main.async {
                    self.downloadTask = profilePicture.loadImage(url: url)
                }
            }
            
            referenceTextView.text = "\(profile.username!) began following you."
            referenceTextView.sizeToFit()
            referenceTextView.textContainer.lineFragmentPadding = 0
            referenceTextView.textContainerInset = UIEdgeInsets.zero
            referenceTextView.delegate = self
            referenceTextView.resolveHashTags()
            
            return cell
        }
    }
}


extension UserActivityViewController: UITextViewDelegate {
    func textView(_ textView: UITextView, shouldInteractWith URL: URL, in characterRange: NSRange, interaction: UITextItemInteraction) -> Bool {
        if let scheme = URL.scheme {
            switch scheme {
            case "mention", "username":
                let username = URL.absoluteString.components(separatedBy: ":")[1]
                loadProfileWithUsername(username: username)
            default:
                print("Normal URL or Hashtag should be impossible check UserActivityVC")
            }
        }
        
        return false
    }
}
