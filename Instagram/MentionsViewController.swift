//
//  MentionsViewController.swift
//  Instagram
//
//  Created by apple  on 15/05/2017.
//  Copyright © 2017 Instagram. All rights reserved.
//

import UIKit

class MentionsViewController: UIViewController {

    var posts: [Post] = []
    let postService = PostService()
    
    @IBOutlet weak var collectionView: UICollectionView!
    override func viewDidLoad() {
        super.viewDidLoad()
        
        if posts.count == 0 {
            noPostsReceived()
        }
        
        let memoryCapacity = 500 * 1024 * 1024
        let diskCapacity = 500 * 1024 * 1024
        let cache = URLCache(memoryCapacity: memoryCapacity, diskCapacity: diskCapacity, diskPath: nil)
        URLCache.shared = cache
        
        let cellNib = UINib(nibName: "ProfilePhotoCell", bundle: nil)
        collectionView.register(cellNib, forCellWithReuseIdentifier: "ProfilePhotoCell")
    }
    
    func noPostsReceived() {
        let alert = UIAlertController(title: "Error", message: "You have not been mentioned in any posts!", preferredStyle: .alert)
        let okAction = UIAlertAction(title: "OK", style: .default, handler: { _ in
            self.navigationController?.popViewController(animated: true)
        })
        
        alert.addAction(okAction)
        
        self.present(alert, animated: true, completion: nil)
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

}

extension MentionsViewController: UICollectionViewDataSource {
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

extension MentionsViewController: UICollectionViewDelegate {
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {        
        let post = posts[indexPath.row]
        postService.userFromId(id: post.userID!, completion: { (profile) in
            let dataDict: [String: Any] = ["profile": profile, "post": post]
            self.goToPost(dataDict: dataDict)
        })
    }
}
