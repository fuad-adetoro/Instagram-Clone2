//
//  AcitivtyViewController.swift
//  Instagram
//
//  Created by apple  on 26/04/2017.
//  Copyright © 2017 Instagram. All rights reserved.
//

import UIKit
import Firebase

class ActivityViewController: UIViewController {

    @IBOutlet weak var tableView: UITableView!
    
    enum Activity {
        case likes
        case following
        case followers
    }
    
    var post: Post?
    var profile: Profile?
    
    var activity: Activity = .likes
    
    var profiles: [Profile] = []
    
    let postService = PostService()
    let accountService = AccountService()
    let currentUser = Auth.auth().currentUser
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let memoryCapacity = 500 * 1024 * 1024
        let diskCapacity = 500 * 1024 * 1024
        let cache = URLCache(memoryCapacity: memoryCapacity, diskCapacity: diskCapacity, diskPath: nil)
        URLCache.shared = cache
        
        tableView.tableFooterView = UIView()
        tableView.estimatedRowHeight = 35
        tableView.rowHeight = UITableViewAutomaticDimension
        
        switch activity {
        case .likes:
            self.title = "Likes"
            let refreshCtrl = UIRefreshControl()
            refreshCtrl.addTarget(self, action: #selector(ActivityViewController.refreshLikes), for: .valueChanged)
            refreshCtrl.tag = 93
            tableView.addSubview(refreshCtrl)
        case .followers:
            self.title = "Followers"
            let refreshCtrl = UIRefreshControl()
            refreshCtrl.addTarget(self, action: #selector(ActivityViewController.refreshFollowers), for: .valueChanged)
            refreshCtrl.tag = 94
            tableView.addSubview(refreshCtrl)
        case .following:
            self.title = "Following"
            let refreshCtrl = UIRefreshControl()
            refreshCtrl.addTarget(self, action: #selector(ActivityViewController.refreshFollowing), for: .valueChanged)
            refreshCtrl.tag = 95
            tableView.addSubview(refreshCtrl)
        }
    }
    
    func refreshLikes() {
        print("Refreshing Likes")
        if post != nil {
            if let refreshCtrl = self.tableView.viewWithTag(93) as? UIRefreshControl {
                refreshCtrl.beginRefreshing()
            
                postService.fetchPostLikes(post: post!, completion: { (profiles) in
                    self.reloadData(with: profiles, refreshControl: refreshCtrl)
                })
            }
        }
    }
    
    func refreshFollowers() {
        if profile != nil {
            if let refreshCtrl = self.tableView.viewWithTag(94) as? UIRefreshControl {
                refreshCtrl.beginRefreshing()
                accountService.fetchFollowers(profile: profile!, completion: { (profiles) in
                    self.reloadData(with: profiles, refreshControl: refreshCtrl)
                })
            }
        }
    }
    
    func refreshFollowing() {
        if profile != nil {
            if let refreshCtrl = self.tableView.viewWithTag(95) as? UIRefreshControl {
                refreshCtrl.beginRefreshing()
                accountService.fetchFollowing(profile: profile!, completion: { (profiles) in
                    self.reloadData(with: profiles, refreshControl: refreshCtrl)
                })
            }
        }
    }
    
    func reloadData(with profiles: [Profile], refreshControl: UIRefreshControl) {
        self.profiles = profiles
        refreshControl.endRefreshing()
        self.tableView.reloadData()
    }
}

extension ActivityViewController: UITableViewDataSource {
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return profiles.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "PostLikers", for: indexPath) as! PostLikers
        
        let profile = profiles[indexPath.row]
        
        cell.configure(profile: profile)
        
        return cell
    }
}

class PostLikers: UITableViewCell {
    @IBOutlet weak var profilePicture: UIImageView!
    @IBOutlet weak var usernameLabel: UILabel!
    @IBOutlet weak var displayNameLabel: UILabel!
    @IBOutlet weak var followButton: UIButton!
    
    @IBAction func followTapped(_ sender: Any) {
        if profile != nil, currentUser != nil {
            if isFollowing {
                accountService.unFollowUser(userID: profile!.userID!, currentUser: currentUser!)
                followButton.setTitle("Follow", for: .normal)
                isFollowing = false
            } else {
                accountService.followUser(userID: profile!.userID!, currentUser: currentUser!)
                followButton.setTitle("Following", for: .normal)
                isFollowing = true
            }
        }
    }
    
    override func awakeFromNib() {
        profilePicture.layer.masksToBounds = true
        profilePicture.layer.cornerRadius = profilePicture.frame.width / 2
    }
    
    
    var isFollowing = false
    let accountService = AccountService()
    let postService = PostService()
    let currentUser = Auth.auth().currentUser
    var profile: Profile?
    
    func configure(profile: Profile) {
        self.profile = profile
        usernameLabel.text = profile.username!
        
        if let displayName = profile.name {
            displayNameLabel.text = displayName
        }
        
        postService.retrieveProfilePicture(userID: profile.userID!) { (profilePicture) in
            DispatchQueue.main.async {
                self.profilePicture.image = profilePicture
            }
        }
        
        if profile.userID! != currentUser!.uid {
            accountService.isFollowingUser(userID: profile.userID!, currentUserID: currentUser!.uid) {     (following) in
                if following {
                    self.isFollowing = true
                    self.followButton.setTitle("Following", for: .normal)
                } else {
                    self.isFollowing = false
                    self.followButton.setTitle("Follow", for: .normal)
                }
            }
        } else {
            followButton.isHidden = true
            followButton.isEnabled = false
        }
    }
}

extension ActivityViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let profile = profiles[indexPath.row]
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        let viewUserProfileVC = storyboard.instantiateViewController(withIdentifier: "ViewUserProfile") as! ViewUserProfileViewController
        viewUserProfileVC.profile = profile
        
        self.navigationController?.pushViewController(viewUserProfileVC, animated: true)
    }
}
