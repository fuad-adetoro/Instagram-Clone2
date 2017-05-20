//
//  HashtagsViewController.swift
//  Instagram
//
//  Created by apple  on 05/05/2017.
//  Copyright © 2017 Instagram. All rights reserved.
//

import UIKit

class HashtagsViewController: UIViewController {

    var hashtag: String?
    let postService = PostService()
    var posts: [Post] = []
    
    @IBOutlet weak var collectionView: UICollectionView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let memoryCapacity = 500 * 1024 * 1024
        let diskCapacity = 500 * 1024 * 1024
        let cache = URLCache(memoryCapacity: memoryCapacity, diskCapacity: diskCapacity, diskPath: nil)
        URLCache.shared = cache

        let cellNib = UINib(nibName: "ProfilePhotoCell", bundle: nil)
        collectionView.register(cellNib, forCellWithReuseIdentifier: "ProfilePhotoCell")
        
        self.title = hashtag
        
        let refreshCtrl = UIRefreshControl()
        refreshCtrl.tag = 90
        refreshCtrl.addTarget(self, action: #selector(HashtagsViewController.reloadPosts), for: .valueChanged)
        self.collectionView.addSubview(refreshCtrl)
    }
    
    func reloadPosts() {
        if let refreshControl = self.view.viewWithTag(90) as? UIRefreshControl {
            refreshControl.beginRefreshing()
            
            postService.fetchPosts(with: hashtag!) { (posts) in
                let sortedPosts = posts.sorted(by: {Date(timeIntervalSince1970: $0.timestamp!) > Date(timeIntervalSince1970: $1.timestamp!)})
                self.posts = sortedPosts
                refreshControl.endRefreshing()
                self.collectionView.reloadData()
            }
        }
    }

    func goToPost(dataDict: [String: Any]) {
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        let profilePostVC = storyboard.instantiateViewController(withIdentifier: "ShowPost") as! ViewProfilePostController
        let post = dataDict["post"] as! Post
        let user = dataDict["user"] as! User
        profilePostVC.post = post
        profilePostVC.user = user
        
        self.navigationController?.pushViewController(profilePostVC, animated: true)
    }
}

extension HashtagsViewController: UICollectionViewDataSource {
    func numberOfSections(in collectionView: UICollectionView) -> Int {
        return 1
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return posts.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "ProfilePhotoCell", for: indexPath) as! ProfilePhotoCell
            
        let post = posts[indexPath.row]
        cell.configure(post: post)
            
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAtIndexPath indexPath: IndexPath) -> CGSize {
        let layout = collectionView.collectionViewLayout as! UICollectionViewFlowLayout
        layout.sectionInset = UIEdgeInsets(top: 2, left: 2, bottom: 2, right: 2)
        layout.minimumInteritemSpacing = 02
        layout.minimumLineSpacing = 02
        layout.invalidateLayout()
        
        return CGSize(width: view.frame.size.width / 3 - 4, height: view.frame.size.width / 3 - 4)
        
    }
}

extension HashtagsViewController: UICollectionViewDelegate {
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        print("Did Select \(indexPath) \(indexPath.row)")
        let post = posts[indexPath.row]
        postService.userFromId(id: post.userID!, completion: { (user) in
            let dataDict: [String: Any] = ["user": user, "post": post]
            self.goToPost(dataDict: dataDict)
        })
    }
}
