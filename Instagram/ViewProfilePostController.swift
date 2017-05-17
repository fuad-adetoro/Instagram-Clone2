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
    let accountService = AccountService()
    
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
        
        self.navigationController?.isNavigationBarHidden = false
    }
    
    func goToComments(){
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        let commentsVC = storyboard.instantiateViewController(withIdentifier: "DisplayComments") as! CommentsViewController
        commentsVC.post = post
        self.navigationController?.pushViewController(commentsVC, animated: true)
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
            let storyboard = UIStoryboard(name: "Main", bundle: nil)
            let hashtagController = storyboard.instantiateViewController(withIdentifier: "hashtagController") as! HashtagsViewController
            hashtagController.posts = posts
            hashtagController.hashtag = hashtag
            self.navigationController?.pushViewController(hashtagController, animated: true)
        }
    }
    
    func displayLikesController(_ sender: UITapGestureRecognizer) {
        postService.fetchPostLikes(post: post!, completion: { (users) in
            if !users.isEmpty {
                let storyboard = UIStoryboard(name: "Main", bundle: nil)
                let activityVC = storyboard.instantiateViewController(withIdentifier: "ActivityControl") as! ActivityViewController
                activityVC.users = users
                activityVC.activity = .likes
                activityVC.user = self.user!
                self.navigationController?.pushViewController(activityVC, animated: true)
            }
        })
    }
    
    func presentComments(_ sender: UITapGestureRecognizer) {
        if let indexPath = self.collectionView.indexPathForItem(at: sender.location(in: self.collectionView)) {
            let storyboard = UIStoryboard(name: "Main", bundle: nil)
            let commentsVC = storyboard.instantiateViewController(withIdentifier: "DisplayComments") as! CommentsViewController
            commentsVC.post = post!
            self.navigationController?.pushViewController(commentsVC, animated: true)
        }
    }
    
    func postOptions(_ sender: UITapGestureRecognizer) {
        if post!.userID! == currentUser!.uid {
            let alert = UIAlertController(title: "Delete post?", message: nil,  preferredStyle: .actionSheet)
            let deleteAction = UIAlertAction(title: "Delete", style: .destructive, handler: { _ in
                self.postService.deletePost(post: self.post!, completion: { (reference) in
                    self.navigationController?.popViewController(animated: true)
                })
            })
            
            let cancelAction = UIAlertAction(title: "Cancel", style: .cancel, handler: nil)
            
            alert.addAction(deleteAction)
            alert.addAction(cancelAction)
            
            present(alert, animated: true, completion: nil)
        } else {
            let alert = UIAlertController(title: "What's up with this post?", message: nil,  preferredStyle: .actionSheet)
            let reportAction = UIAlertAction(title: "Report", style: .default, handler: { _ in
                self.postService.reportPost(post: self.post!, reporter: self.currentUser!.uid)
            })
            let cancelAction = UIAlertAction(title: "Cancel", style: .default, handler: nil)
            
            alert.addAction(reportAction)
            alert.addAction(cancelAction)
            
            present(alert, animated: true, completion: nil)
        }
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
            
            cell.captionTextView.text = "\(username) \(caption)"
            cell.captionTextView.resolveHashTags()
            cell.captionTextView.sizeToFit()
            cell.captionTextView.delegate = self
            
            let likesTapped = UITapGestureRecognizer(target: self, action: #selector(ViewProfilePostController.displayLikesController(_:)))
            likesTapped.numberOfTapsRequired = 1
            cell.likesLabel.addGestureRecognizer(likesTapped)
            
            let tapGesture = UITapGestureRecognizer(target: self, action: #selector(ViewProfilePostController.presentComments(_:)))
            tapGesture.numberOfTapsRequired = 1
            cell.captionTextView.addGestureRecognizer(tapGesture)
            
            let optionsTapped = UITapGestureRecognizer(target: self, action: #selector(ViewProfilePostController.postOptions(_:)))
            optionsTapped.numberOfTapsRequired = 1
            cell.optionsButton.addGestureRecognizer(optionsTapped)
            
            cell.configure(post: post!)
            
            return cell
        } else {
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "PostCell", for: indexPath) as! PostCell
            
            let commentsButton = cell.viewWithTag(2005) as! UIButton
            commentsButton.addTarget(self, action: #selector(ViewProfilePostController.goToComments), for: .touchUpInside)
            
            let likesTapped = UITapGestureRecognizer(target: self, action: #selector(ViewProfilePostController.displayLikesController(_:)))
            likesTapped.numberOfTapsRequired = 1
            cell.likesLabel.addGestureRecognizer(likesTapped)
            
            let optionsTapped = UITapGestureRecognizer(target: self, action: #selector(ViewProfilePostController.postOptions(_:)))
            optionsTapped.numberOfTapsRequired = 1
            cell.optionsButton.addGestureRecognizer(optionsTapped)
            
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

extension ViewProfilePostController: UITextViewDelegate {
    func textView(_ textView: UITextView, shouldInteractWith URL: URL, in characterRange: NSRange, interaction: UITextItemInteraction) -> Bool {
        if let scheme = URL.scheme {
            switch scheme {
            case "hash":
                let hashtag = "#\(URL.absoluteString.components(separatedBy: ":")[1])"
                loadHashtagController(hashtag: hashtag)
            case "mention", "username":
                let username = URL.absoluteString.components(separatedBy: ":")[1]
                loadProfileWithUsername(username: username)
            default:
                print("NOrmal URL")
            }
        }
        
        return false
    }
}

extension ViewProfilePostController: UINavigationBarDelegate {
    func position(for bar: UIBarPositioning) -> UIBarPosition {
        return .topAttached
    }
}
