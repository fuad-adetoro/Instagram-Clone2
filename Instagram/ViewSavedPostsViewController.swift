//
//  ViewSavedPostsViewController.swift
//  Instagram
//
//  Created by apple  on 22/04/2017.
//  Copyright © 2017 Instagram. All rights reserved.
//

import UIKit
import Firebase

class ViewSavedPostsViewController: UIViewController {

    @IBOutlet weak var savedPostsCollectionView: UICollectionView!
    
    var posts: [Post] = []
    var savedPosts: [SavedPosts] = []
    let postService = PostService()
    var currentUser: FIRUser?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let memoryCapacity = 500 * 1024 * 1024
        let diskCapacity = 500 * 1024 * 1024
        let cache = URLCache(memoryCapacity: memoryCapacity, diskCapacity: diskCapacity, diskPath: nil)
        URLCache.shared = cache

        let cellNib = UINib(nibName: "ProfilePhotoCell", bundle: nil)
        savedPostsCollectionView.register(cellNib, forCellWithReuseIdentifier: "ProfilePhotoCell")
        
        let refreshCtrl = UIRefreshControl()
        refreshCtrl.tag = 94
        refreshCtrl.addTarget(self, action: #selector(ViewSavedPostsViewController.reloadPosts) , for: .valueChanged)
        savedPostsCollectionView?.addSubview(refreshCtrl)
        
        print("Posts: \(posts)")
    }
    
    func reloadPosts() {
        postService.usersSavedPosts(currentUser: currentUser!) { (posts) in
            let sortedPosts = posts.sorted(by: {Date(timeIntervalSince1970: $0.timestamp!) > Date(timeIntervalSince1970: $1.timestamp!)})
            if let refreshCtrl = self.view.viewWithTag(94) as? UIRefreshControl {
                refreshCtrl.endRefreshing()
            }
            self.posts = sortedPosts
            self.savedPostsCollectionView.reloadData()
        }
    }

    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "pushFromSavedPost" {
            let picturePostVC = segue.destination as! ViewProfilePostController
            let dataDict = sender as! [String: Any]
            let post = dataDict["post"] as! Post
            let user = dataDict["user"] as! User
            picturePostVC.post = post
            picturePostVC.user = user
        }
    }
    
    func goToPicture(dataDict: [String: Any]) {
        performSegue(withIdentifier: "pushFromSavedPost", sender: dataDict)
    }
}

extension ViewSavedPostsViewController: UICollectionViewDataSource {
    func numberOfSections(in collectionView: UICollectionView) -> Int {
        return 2
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        if section == 0 {
            return 1
        } else {
            return posts.count
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        if indexPath.section == 0 {
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "SavedTextCell", for: indexPath)
            
            return cell
        } else {
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "ProfilePhotoCell", for: indexPath) as! ProfilePhotoCell
            
            let post = posts[indexPath.row]
            cell.configure(post: post)
            
            return cell
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAtIndexPath indexPath: IndexPath) -> CGSize {
        
        if indexPath.section == 0 && indexPath.row == 0 {
            return CGSize(width: self.view.frame.width, height: CGFloat(45))
        } else {
            let layout = collectionView.collectionViewLayout as! UICollectionViewFlowLayout
            layout.sectionInset = UIEdgeInsets(top: 2, left: 2, bottom: 2, right: 2)
            layout.minimumInteritemSpacing = 02
            layout.minimumLineSpacing = 02
            layout.invalidateLayout()
            
            return CGSize(width: view.frame.size.width / 3 - 4, height: view.frame.size.width / 3 - 4)
        }
        
    }
}

extension ViewSavedPostsViewController: UICollectionViewDelegate {
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        if indexPath.section == 1 {
            let post = posts[indexPath.row]
            postService.userFromId(id: post.userID!, completion: { (user) in
                let dataDict: [String: Any] = ["user": user, "post": post]
                self.goToPicture(dataDict: dataDict)
            })
        }
    }
}

