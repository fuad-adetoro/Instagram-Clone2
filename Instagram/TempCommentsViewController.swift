//
//  TempCommentsViewController.swift
//  Instagram
//
//  Created by Fuad Adetoro on 20/05/2017.
//  Copyright © 2017 Instagram. All rights reserved.
//

import UIKit
import Firebase

class TempCommentsViewController: UIViewController {

    let postService = PostService()
    let authService = AuthService()
    let accountService = AccountService()
    
    var downloadTask: URLSessionDownloadTask!
        
    var post: Post!
    let currentUser = FIRAuth.auth()?.currentUser
    var comments: [Comments] = []
    
    func fetchComments() {
        postService.fetchComments(post: post!) { (comments) in
            let sortedComments = comments.sorted(by: {Date(timeIntervalSince1970: $0.timestamp!) > Date(timeIntervalSince1970: $1.timestamp!)})
            self.comments = sortedComments
            //self.tableView.reloadData()
        }
    }
    
    var keyboardHeight: CGFloat = 253
    
    override func viewDidLoad() {
        super.viewDidLoad()

        let memoryCapacity = 500 * 1024 * 1024
        let diskCapacity = 500 * 1024 * 1024
        let cache = URLCache(memoryCapacity: memoryCapacity, diskCapacity: diskCapacity, diskPath: nil)
        URLCache.shared = cache
        
        //tableView.tableFooterView = UIView()
        
        NotificationCenter.default.addObserver(self, selector: #selector(CommentsViewController.keyboardWillShow(_:)), name: .UIKeyboardWillShow, object: nil)
        
        fetchComments()
    }
    
    func keyboardWillShow(_ notification: NSNotification) {
        if let keyboardSize = (notification.userInfo?[UIKeyboardFrameEndUserInfoKey] as? NSValue)?.cgRectValue {
            self.keyboardHeight = keyboardSize.height
            
            //self.tableView.rowHeight = UITableViewAutomaticDimension
        }
    }
    
    func animateViewUp(by value: CGFloat) {
        UIView.animate(withDuration: 0.3) {
            self.view.frame.origin.y -= value
        }
    }
    
    func animateViewDown(by value: CGFloat) {
        UIView.animate(withDuration: 0.3) {
            self.view.frame.origin.y += value
        }
    }
    
    func loadProfileWithUsername(username: String) {
        accountService.fetchUserWithUsername(username: username) { (user) in
            let storyboard = UIStoryboard(name: "Main", bundle: nil)
            let profileVC = storyboard.instantiateViewController(withIdentifier: "ViewUserProfile") as! ViewUserProfileViewController
            profileVC.user = user
            self.navigationController?.pushViewController(profileVC, animated: true)
        }
    }
    
    func loadHashtagController(hashtag: String) {
        postService.fetchPosts(with: hashtag) { (posts) in
            let dataDict: [String: Any] = ["hashtag": hashtag, "posts": posts]
            let storyboard = UIStoryboard(name: "Main", bundle: nil)
            let hashtagController = storyboard.instantiateViewController(withIdentifier: "hashtagController") as! HashtagsViewController
            hashtagController.posts = posts
            hashtagController.hashtag = hashtag
            self.navigationController?.pushViewController(hashtagController, animated: true)
        }
    }
}

extension TempCommentsViewController: UICollectionViewDataSource {
    func numberOfSections(in collectionView: UICollectionView) -> Int {
        return 2
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        if section == 0 {
            if post.caption != nil {
                return 1
            } else {
                return 0
            }
        } else {
            return comments.count
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        if indexPath.section == 0 {
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "SomeCollectionViewCell", for: indexPath)
            
            return cell
        } else {
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "SomeCollectionViewCell", for: indexPath)
            
            return cell
        }
    }
}
