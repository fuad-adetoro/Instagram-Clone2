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
    
    @IBOutlet weak var profileCollectionView: UICollectionView!
    var image = #imageLiteral(resourceName: "user-placeholder.jpg")
    
    let postService = PostService()
    let authService = AuthService()
    let accountService = AccountService()
    
    var posts: [Post] = []
    var images: [String: UIImage] = [:]
    var profilePicURL: String?
    let currentUser = FIRAuth.auth()?.currentUser
    
    // Loading "PostCellWithCaption" nib to postCellCaptionNib and forcing it to be an NSArray
    let postCellCaptionNib = Bundle.main.loadNibNamed("PostCellWithCaption", owner: PostCellWithCaption.self, options: nil)! as NSArray
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let memoryCapacity = 500 * 1024 * 1024
        let diskCapacity = 500 * 1024 * 1024
        let cache = URLCache(memoryCapacity: memoryCapacity, diskCapacity: diskCapacity, diskPath: nil)
        URLCache.shared = cache
        
        var cellNib = UINib(nibName: "PostCell", bundle: nil)
        profileCollectionView.register(cellNib, forCellWithReuseIdentifier: "PostCell")
        
        cellNib = UINib(nibName: "PostCellWithCaption", bundle: nil)
        profileCollectionView.register(cellNib, forCellWithReuseIdentifier: "PostCellWithCaption")
        
        self.navigationItem.titleView = UIImageView(image: #imageLiteral(resourceName: "homelogo"))
        
        fetchPosts()
        
        // Creating refresh control to refresh the data displayed.
        let refreshCtrl = UIRefreshControl()
        refreshCtrl.tag = 92
        refreshCtrl.addTarget(self, action: #selector(HomeViewController.fetchPosts) , for: .valueChanged)
        profileCollectionView?.addSubview(refreshCtrl)
        
        self.tabBarController?.delegate = UIApplication.shared.delegate as? UITabBarControllerDelegate
        print("Current USeriD: \(currentUser!.uid)")
    }
    
    func fetchPosts() {
        postService.fetchPosts { (userPosts) in
            let postsSorted = userPosts.sorted(by: {Date(timeIntervalSince1970: $0.timestamp!) > Date(timeIntervalSince1970: $1.timestamp!)})
            self.posts = postsSorted
            var loopCount = 0
            
            for post in postsSorted {
                loopCount = loopCount + 1
                self.postService.retrievePostPicture(imageURL: post.imageURL!, completion: { (image) in
                    self.images.updateValue(image, forKey: post.key)
                    
                    if loopCount == postsSorted.count {
                        if let refreshCtrl = self.view.viewWithTag(92) as? UIRefreshControl {
                            refreshCtrl.endRefreshing()
                        }
                        
                        self.profileCollectionView.reloadData()
                    }
                })
            }
        }
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "ViewUserProfile" {
            let viewUserProfileVC = segue.destination as! ViewUserProfileViewController
            let user = sender as! User
            viewUserProfileVC.user = user
        } else if segue.identifier == "ActivityControl" {
            let activityVC = segue.destination as! ActivityViewController
            let dataDict = sender as! [String: Any]
            let users = dataDict["users"] as! [User]
            let post = dataDict["post"] as! Post
            activityVC.users = users
            activityVC.post = post
            activityVC.activity = .likes
        } else if segue.identifier == "hashtagController" {
            let hashtagVC = segue.destination as! HashtagsViewController
            let dataDict = sender as! [String: Any]
            let posts = dataDict["posts"] as! [Post]
            let hashtag = dataDict["hashtag"] as! String
            let sortedPosts = posts.sorted(by: {Date(timeIntervalSince1970: $0.timestamp!) > Date(timeIntervalSince1970: $1.timestamp!)})
            hashtagVC.posts = sortedPosts
            hashtagVC.hashtag = hashtag
        }
    }
    
    func goToComments(_ sender: AnyObject){
        let buttonPosition:CGPoint = sender.convert(CGPoint.zero, to: self.profileCollectionView)
        let indexPath = self.profileCollectionView.indexPathForItem(at: buttonPosition)
        let row = indexPath?.row
    
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        let commentsVC = storyboard.instantiateViewController(withIdentifier: "DisplayComments") as! CommentsViewController
        let post = posts[row!]
        commentsVC.post = post
        self.navigationController?.pushViewController(commentsVC, animated: true)
    }
    
    func goToProfile(_ sender: AnyObject) {
        let buttonPosition:CGPoint = sender.convert(CGPoint.zero, to: self.profileCollectionView)
        let indexPath = self.profileCollectionView.indexPathForItem(at: buttonPosition)
        let row = indexPath?.row
        print("ROW: \(row!)")
        let post = posts[row!]
        postService.userFromId(id: post.userID!) { (user) in
            self.performSegue(withIdentifier: "ViewUserProfile", sender: user)
        }
    }
    
    func presentComments(_ sender: UITapGestureRecognizer) {
        if let indexPath = self.profileCollectionView.indexPathForItem(at: sender.location(in: self.profileCollectionView)) {
            let storyboard = UIStoryboard(name: "Main", bundle: nil)
            let commentsVC = storyboard.instantiateViewController(withIdentifier: "DisplayComments") as! CommentsViewController
            let post = posts[indexPath.row]
            commentsVC.post = post
            self.navigationController?.pushViewController(commentsVC, animated: true)
        }
    }
    
    func loadProfileWithUsername(username: String) {
        accountService.fetchUserWithUsername(username: username) { (user) in
            self.performSegue(withIdentifier: "ViewUserProfile", sender: user)
        }
    }
    
    func loadHashtagController(hashtag: String) {
        postService.fetchPosts(with: hashtag) { (posts) in
            print("Segue")
            let dataDict: [String: Any] = ["hashtag": hashtag, "posts": posts]
            self.performSegue(withIdentifier: "hashtagController", sender: dataDict)
        }
    }
    
    func displayLikesController(_ sender: UITapGestureRecognizer) {
        if let indexPath = self.profileCollectionView.indexPathForItem(at: sender.location(in: self.profileCollectionView)) {
            let post = posts[indexPath.row]
            postService.fetchPostLikes(post: post, completion: { (users) in
                if !users.isEmpty {
                    let dataDict: [String: Any] = ["users": users, "post": post]
                    self.performSegue(withIdentifier: "ActivityControl", sender: dataDict)
                }
            })
        }
    }

    func postOptions(_ sender: UITapGestureRecognizer) {
        if let indexPath = self.profileCollectionView.indexPathForItem(at: sender.location(in: self.profileCollectionView)) {
            let post = posts[indexPath.row]
            
            if post.userID! == currentUser!.uid {
                let alert = UIAlertController(title: "Delete post?", message: nil,  preferredStyle: .actionSheet)
                let deleteAction = UIAlertAction(title: "Delete", style: .destructive, handler: { _ in
                    self.postService.deletePost(post: post, completion: { (reference) in
                        if self.posts.count == 1 {
                            self.posts = []
                            self.profileCollectionView.reloadData()
                        } else {
                            self.fetchPosts()
                        }
                    })
                })
                
                let cancelAction = UIAlertAction(title: "Cancel", style: .cancel, handler: nil)
                
                alert.addAction(deleteAction)
                alert.addAction(cancelAction)
                
                present(alert, animated: true, completion: nil)
            } else {
                let alert = UIAlertController(title: "What's up with this post?", message: nil,  preferredStyle: .actionSheet)
                let reportAction = UIAlertAction(title: "Report", style: .default, handler: { _ in
                    self.postService.reportPost(post: post, reporter: self.currentUser!.uid)
                })
                let cancelAction = UIAlertAction(title: "Cancel", style: .default, handler: nil)
                
                alert.addAction(reportAction)
                alert.addAction(cancelAction)
                
                present(alert, animated: true, completion: nil)
            }
        }
    }
    
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
            
            cell.configure(post: post)
            
            let commentsButton = cell.viewWithTag(2005) as! UIButton
            commentsButton.addTarget(self, action: #selector(HomeViewController.goToComments(_:)), for: .touchUpInside)
            
            cell.usernameLabel.addTarget(self, action: #selector(HomeViewController.goToProfile(_:)), for: .touchUpInside)
            
            let username = post.username!
            
            cell.captionTextView.text = "\(username) \(caption)"
            cell.captionTextView.resolveHashTags()
            cell.captionTextView.sizeToFit()
            
            let tapGesture = UITapGestureRecognizer(target: self, action: #selector(HomeViewController.presentComments(_:)))
            tapGesture.numberOfTapsRequired = 1
            cell.captionTextView.addGestureRecognizer(tapGesture)
            cell.captionTextView.delegate = self
            
            let likesTapped = UITapGestureRecognizer(target: self, action: #selector(HomeViewController.displayLikesController))
            likesTapped.numberOfTapsRequired = 1
            cell.likesLabel.addGestureRecognizer(likesTapped)
            
            let optionsTapped = UITapGestureRecognizer(target: self, action: #selector(HomeViewController.postOptions(_:)))
            optionsTapped.numberOfTapsRequired = 1
            cell.optionsButton.addGestureRecognizer(optionsTapped)
            
            cell.contentView.frame = cell.bounds
            cell.contentView.autoresizingMask = [.flexibleHeight]
            
            return cell
        } else {
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "PostCell", for: indexPath) as! PostCell
            
            let commentsButton = cell.viewWithTag(2005) as! UIButton
            commentsButton.addTarget(self, action: #selector(HomeViewController.goToComments(_:)), for: .touchUpInside)
                        
            cell.usernameLabel.addTarget(self, action: #selector(HomeViewController.goToProfile(_:)), for: .touchUpInside)
            
            cell.configure(post: post)
            
            let likesTapped = UITapGestureRecognizer(target: self, action: #selector(HomeViewController.displayLikesController))
            likesTapped.numberOfTapsRequired = 1
            cell.likesLabel.addGestureRecognizer(likesTapped)
            
            let optionsTapped = UITapGestureRecognizer(target: self, action: #selector(HomeViewController.postOptions(_:)))
            optionsTapped.numberOfTapsRequired = 1
            cell.optionsButton.addGestureRecognizer(optionsTapped)
            
            return cell
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAtIndexPath indexPath: IndexPath) -> CGSize {
        let postObject = postCellCaptionNib.object(at: 0) as! PostCellWithCaption
        
        let post = posts[indexPath.row]
        if post.caption != nil {
            postObject.configure(username: post.username!, caption: post.caption!)
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

extension HomeViewController : UITextViewDelegate {
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
