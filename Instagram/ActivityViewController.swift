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
    var user: User?
    
    var activity: Activity = .likes
    
    var users: [User] = []
    
    let postService = PostService()
    let accountService = AccountService()
    let currentUser = FIRAuth.auth()?.currentUser
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
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
            
                postService.fetchPostLikes(post: post!, completion: { (users) in
                    self.reloadData(with: users, refreshControl: refreshCtrl)
                })
            }
        }
    }
    
    func refreshFollowers() {
        if user != nil {
            if let refreshCtrl = self.tableView.viewWithTag(94) as? UIRefreshControl {
                refreshCtrl.beginRefreshing()
                accountService.fetchFollowers(user: user!, completion: { (users) in
                    self.reloadData(with: users, refreshControl: refreshCtrl)
                })
            }
        }
    }
    
    func refreshFollowing() {
        if user != nil {
            if let refreshCtrl = self.tableView.viewWithTag(95) as? UIRefreshControl {
                refreshCtrl.beginRefreshing()
                accountService.fetchFollowing(user: user!, completion: { (users) in
                    self.reloadData(with: users, refreshControl: refreshCtrl)
                })
            }
        }
    }
    
    func reloadData(with users: [User], refreshControl: UIRefreshControl) {
        self.users = users
        refreshControl.endRefreshing()
        self.tableView.reloadData()
    }
}

extension ActivityViewController: UITableViewDataSource {
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return users.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "PostLikers", for: indexPath) as! PostLikers
        
        let user = users[indexPath.row]
        
        cell.configure(user: user)
        
        return cell
    }
}

class PostLikers: UITableViewCell {
    @IBOutlet weak var profilePicture: UIImageView!
    @IBOutlet weak var usernameLabel: UILabel!
    @IBOutlet weak var displayNameLabel: UILabel!
    @IBOutlet weak var followButton: UIButton!
    
    @IBAction func followTapped(_ sender: Any) {
        if user != nil, currentUser != nil {
            if isFollowing {
                accountService.unFollowUser(userID: user!.userID!, currentUser: currentUser!)
                followButton.setTitle("Follow", for: .normal)
                isFollowing = false
            } else {
                accountService.followUser(userID: user!.userID!, currentUser: currentUser!)
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
    let currentUser = FIRAuth.auth()?.currentUser
    var user: User?
    
    func configure(user: User) {
        self.user = user
        usernameLabel.text = user.username!
        
        if let displayName = user.name {
            displayNameLabel.text = displayName
        }
        
        postService.retrieveProfilePicture(userID: user.userID!) { (profilePicture) in
            DispatchQueue.main.async {
                self.profilePicture.image = profilePicture
            }
        }
        
        if user.userID! != currentUser!.uid {
            accountService.isFollowingUser(userID: user.userID!, currentUserID: currentUser!.uid) {     (following) in
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
        let user = users[indexPath.row]
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        let viewUserProfileVC = storyboard.instantiateViewController(withIdentifier: "ViewUserProfile") as! ViewUserProfileViewController
        viewUserProfileVC.user = user
        
        self.navigationController?.pushViewController(viewUserProfileVC, animated: true)
    }
}
