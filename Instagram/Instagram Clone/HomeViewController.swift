//
//  HomeViewController.swift
//  Instagram Clone
//
//  Created by Fuad on 28/03/2017.
//  Copyright © 2017 FuadAdetoro. All rights reserved.
//

import UIKit
import Firebase

class HomeViewController: UIViewController {
    
    @IBOutlet weak var collectionView: UICollectionView!
    var image = #imageLiteral(resourceName: "user-placeholder.jpg")
    
    let postService = PostService()
    let authService = AuthService()
    
    var posts: [Post] = []
    var profilePicURL: String?
    
    var flowLayout: UICollectionViewFlowLayout {
        return self.collectionView?.collectionViewLayout as! UICollectionViewFlowLayout
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.flowLayout.estimatedItemSize = CGSize(width: self.view.frame.width, height: 100)
        
        var cellNib = UINib(nibName: "PostCell", bundle: nil)
        collectionView.register(cellNib, forCellWithReuseIdentifier: "PostCell")
        
        cellNib = UINib(nibName: "PostCellWithCaption", bundle: nil)
        collectionView.register(cellNib, forCellWithReuseIdentifier: "PostCellWithCaption")
        
        self.navigationItem.titleView = UIImageView(image: #imageLiteral(resourceName: "homelogo"))
        
        postService.fetchPosts { (userPosts) in
            self.posts = userPosts
            self.collectionView.reloadData()
        }
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "ShowComments" {
            let commentsVC = segue.destination as! CommentsViewController
            let row = sender as! Int
            commentsVC.post = posts[row]
        }
    }
    
    func goToComments(_ sender: AnyObject){
        let buttonPosition:CGPoint = sender.convert(CGPoint.zero, to: self.collectionView)
        let indexPath = self.collectionView.indexPathForItem(at: buttonPosition)
        let row = indexPath?.row
    
        performSegue(withIdentifier: "ShowComments", sender: row)
    }
    
    let sizingNibNew = Bundle.main.loadNibNamed("PostCellWithCaption", owner: PostCellWithCaption.self, options: nil) as! NSArray
}

extension HomeViewController: UICollectionViewDataSource {
    func numberOfSections(in collectionView: UICollectionView) -> Int {
        return 1
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return posts.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let post = posts[indexPath.row]
        
        if let caption = post.caption {
            print("With Caption: \(caption)")
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "PostCellWithCaption", for: indexPath) as! PostCellWithCaption
            
            let commentsButton = cell.viewWithTag(2005) as! UIButton
            commentsButton.addTarget(self, action: #selector(HomeViewController.goToComments(_:)), for: .touchUpInside)
        
            cell.configure(post: post)
        
            return cell
        } else {
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "PostCell", for: indexPath) as! PostCell
            
            let commentsButton = cell.viewWithTag(2005) as! UIButton
            commentsButton.addTarget(self, action: #selector(HomeViewController.goToComments(_:)), for: .touchUpInside)
            
            cell.configure(post: post)
            
            return cell
        }
    }
    
    /*func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAtIndexPath indexPath: IndexPath) -> CGSize {
        
        guard let data = datasourceArray?[indexPath.item] else {
            return CGSizeZero
        }
        let sectionInset = self.collectionView?.collectionViewLayout.sectionInset
        let widthToSubtract = sectionInset!.left + sectionInset!.right
        
        let requiredWidth = collectionView.bounds.size.width
        
        
        let targetSize = CGSize(width: requiredWidth, height: 0)
        
        self.sizingNibNew = (sizingNibNew.objectAtIndex(0) as? PostCellWithCaption)!
        
        self.sizingNibNew.configureCell(data as! CustomCellData, delegate: self)
        let adequateSize = self.sizingNibNew.preferredLayoutSizeFittingSize(targetSize)
        return CGSize(width: (self.collectionView?.bounds.width)! - widthToSubtract, height: adequateSize.height)
    }*/
}
