//
//  ViewProfilePostController.swift
//  Instagram Clone
//
//  Created by Fuad on 04/04/2017.
//  Copyright © 2017 FuadAdetoro. All rights reserved.
//

import UIKit
import Firebase

class ViewProfilePostController: UIViewController {

    var post: Post?
    var user: User?
    let currentUser = FIRAuth.auth()?.currentUser
    let postService = PostService()
    
    @IBOutlet weak var collectionView: UICollectionView!
    
    let postCellCaptionNib = Bundle.main.loadNibNamed("PostCellWithCaption", owner: PostCellWithCaption.self, options: nil)! as NSArray
    
    @IBAction func reloadData(_ sender: Any) {
        let activityIndicator = UIActivityIndicatorView(frame: CGRect(x: 0, y: 0, width: 20, height: 20))
        let barButton = UIBarButtonItem(customView: activityIndicator)
        self.navigationItem.setRightBarButton(barButton, animated: true)
        activityIndicator.startAnimating()
        
        postService.reloadPost(post: post!) { (post) in
            
            activityIndicator.stopAnimating()
            let refreshButton = UIBarButtonItem(barButtonSystemItem: UIBarButtonSystemItem.refresh, target: self, action: #selector(self.reloadData(_:)))
            self.navigationItem.setRightBarButton(refreshButton, animated: true)
            self.post = post
            self.collectionView.reloadData()
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        var cellNib = UINib(nibName: "PostCell", bundle: nil)
        collectionView.register(cellNib, forCellWithReuseIdentifier: "PostCell")
        
        cellNib = UINib(nibName: "PostCellWithCaption", bundle: nil)
        collectionView.register(cellNib, forCellWithReuseIdentifier: "PostCellWithCaption")
    }
    
    func goToComments(){
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        let commentsVC = storyboard.instantiateViewController(withIdentifier: "DisplayComments") as! CommentsViewController
        commentsVC.post = post
        self.navigationController?.pushViewController(commentsVC, animated: true)
    }
}

extension ViewProfilePostController: UICollectionViewDataSource {
    func numberOfSections(in collectionView: UICollectionView) -> Int {
        return 1
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return 1
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        if let caption = post!.caption {
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "PostCellWithCaption", for: indexPath) as! PostCellWithCaption
                        
            let commentsButton = cell.viewWithTag(2005) as! UIButton
            commentsButton.addTarget(self, action: #selector(ViewProfilePostController.goToComments), for: .touchUpInside)
            
            let username = user!.username!
            
            let tapGesture = UITapGestureRecognizer(target: self, action: #selector(ViewProfilePostController.goToComments))
            cell.captionTextView.addGestureRecognizer(tapGesture)
            
            cell.captionTextView.setText(text: "\(username) \(caption)", withHashtagColor: UIColor.blue, andMentionColor: UIColor.blue, andCallback: { (strings, type) in
                //
            }, normalFont: UIFont.systemFont(ofSize: 9.0), hashtagFont: UIFont.boldSystemFont(ofSize: 11), mentionFont: UIFont.boldSystemFont(ofSize: 11))
            cell.captionTextView.sizeToFit()
            
            cell.configure(post: post!)
            
            return cell
        } else {
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "PostCell", for: indexPath) as! PostCell
            
            let commentsButton = cell.viewWithTag(2005) as! UIButton
            commentsButton.addTarget(self, action: #selector(ViewProfilePostController.goToComments), for: .touchUpInside)
                    
            cell.configure(post: post!)
            
            return cell
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAtIndexPath indexPath: IndexPath) -> CGSize {
        let postObject = postCellCaptionNib.object(at: 0) as! PostCellWithCaption
        
        if post!.caption != nil {
            postObject.configure(username: user!.username!, caption: post!.caption!)
            let newHeight = postObject.preferredLayoutSizeFittingSize(targetSize: CGSize(width: self.view.frame.width, height: 0)).height
            if newHeight == 0 {
                return CGSize(width: self.view.frame.width, height: 470)
            } else {
                return CGSize(width: self.view.frame.width, height: newHeight)
            }
        } else {
            return CGSize(width: self.view.frame.width, height: 437)
        }
    }
}

extension ViewProfilePostController: UINavigationBarDelegate {
    func position(for bar: UIBarPositioning) -> UIBarPosition {
        return .topAttached
    }
}
