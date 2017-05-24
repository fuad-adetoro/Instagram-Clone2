//
//  TempProfilePageViewController.swift
//  Instagram Clone
//
//  Created by Fuad on 28/03/2017.
//  Copyright © 2017 FuadAdetoro. All rights reserved.
//

// IMPLEMENT NEW FIREBASE FEATURE MULTIPLE LOGGED IN USERS.

import UIKit
import Firebase

class ProfilePageViewController: UIViewController {
    
    enum PostMode {
        case gridView
        case listView
    }
    
    var postMode: PostMode = .gridView
    
    @IBOutlet weak var profileCollectionView: UICollectionView!
    
    @IBAction func logoutAction(_ sender: Any) {
        let alert = UIAlertController(title: "Log Out?", message: "Are You Sure?", preferredStyle: .alert)
        
        let logoutAction = UIAlertAction(title: "Logout", style: .destructive) { _ in
            self.authService.logUserOut(currentUser: self.currentUser, completion: { (status) in
                if status as! Bool {
                    let storyboard = UIStoryboard(name: "Main", bundle: nil)
                    let navigationController = storyboard.instantiateInitialViewController() as! UINavigationController
                    
                    self.present(navigationController, animated: true, completion: nil)
                } else {
                    let alert = UIAlertController(title: "Error Logging Out!", message: "There seemed to be error logging out, please try again.", preferredStyle: .alert)
                    let okAction = UIAlertAction(title: "OK", style: .default, handler: nil)
                    
                    alert.addAction(okAction)
                    
                    self.present(alert, animated: true, completion: nil)
                }
            })
        }
        let cancelAction = UIAlertAction(title: "Cancel", style: .cancel, handler: nil)
        
        alert.addAction(logoutAction)
        alert.addAction(cancelAction)
        
        self.present(alert, animated: true, completion: nil)
    }
    
    
    var posts: [Post] = []
    var users: [User] = []
    let postService = PostService()
    let accountService = AccountService()
    let authService = AuthService()
    let currentUser = FIRAuth.auth()?.currentUser
    var user: User?
    
    let postCellCaptionNib = Bundle.main.loadNibNamed("PostCellWithCaption", owner: PostCellWithCaption.self, options: nil)! as NSArray
    let profileCellNib = Bundle.main.loadNibNamed("ProfileCellNib", owner: ProfileCellNib.self, options: nil)! as NSArray
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let memoryCapacity = 500 * 1024 * 1024
        let diskCapacity = 500 * 1024 * 1024
        let cache = URLCache(memoryCapacity: memoryCapacity, diskCapacity: diskCapacity, diskPath: nil)
        URLCache.shared = cache
        
        var cellNib = UINib(nibName: "ProfileCellNib", bundle: nil)
        profileCollectionView.register(cellNib, forCellWithReuseIdentifier: "ProfileCellNib")
        
        cellNib = UINib(nibName: "ProfileOrganizeCellNib", bundle: nil)
        profileCollectionView.register(cellNib, forCellWithReuseIdentifier: "ProfileOrganizeCellNib")
        
        cellNib = UINib(nibName: "ProfilePhotoCell", bundle: nil)
        profileCollectionView.register(cellNib, forCellWithReuseIdentifier: "ProfilePhotoCell")
        
        cellNib = UINib(nibName: "PostCellWithCaption", bundle: nil)
        profileCollectionView.register(cellNib, forCellWithReuseIdentifier: "PostCellWithCaption")
        
        cellNib = UINib(nibName: "PostCell", bundle: nil)
        profileCollectionView.register(cellNib, forCellWithReuseIdentifier: "PostCell")
        
        let refreshCtrl = UIRefreshControl()
        refreshCtrl.tag = 93
        refreshCtrl.addTarget(self, action: #selector(ProfilePageViewController.fetchUser) , for: .valueChanged)
        profileCollectionView?.addSubview(refreshCtrl)
        
        fetchUser()
        
        self.profileCollectionView.isPrefetchingEnabled = false
        
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        profileCollectionView.collectionViewLayout.invalidateLayout()
    }
    
    func fetchUser() {
        postService.fetchUser(user: currentUser!) { (user) in
            self.navigationItem.title = user.username!
            self.user = user
            
            self.fetchPosts()
        }
    }
    
    func fetchPosts() {
        self.postService.fetchPosts(user: self.currentUser!) { (userPosts) in
            let postsSorted = userPosts.sorted(by: {Date(timeIntervalSince1970: $0.timestamp!) > Date(timeIntervalSince1970: $1.timestamp!)})
            self.posts = postsSorted
            if let refreshCtrl = self.view.viewWithTag(93) as? UIRefreshControl {
                refreshCtrl.endRefreshing()
            }
            DispatchQueue.main.async {
                self.profileCollectionView.reloadData()
                self.profileCollectionView.collectionViewLayout.invalidateLayout()
            }
        }
    }
    
    var image: UIImage?
    var updatePicture = false
    
    func show(image: UIImage) {
        self.image = image
        self.updatePicture = true
        self.profileCollectionView.reloadData()
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "pushToPost" {
            let viewProfilePostVC = segue.destination as! ViewProfilePostController
            let dataDict = sender as! [String: Any]
            let post = dataDict["post"] as! Post
            let user = dataDict["user"] as! User
            viewProfilePostVC.post = post
            viewProfilePostVC.user = user
        } else if segue.identifier == "EditProfile" {
            let navigationController = segue.destination as! UINavigationController
            let editProfileVC = navigationController.topViewController as! EditProfileViewController
            let currentUser = FIRAuth.auth()?.currentUser
            let user = currentUser!
            editProfileVC.user = user
        } else if segue.identifier == "ShowSavedPosts" {
            let savedPostsVC = segue.destination as! ViewSavedPostsViewController
            let posts = sender as! [Post]
            let sortedPosts = posts.sorted(by: {Date(timeIntervalSince1970: $0.timestamp!) > Date(timeIntervalSince1970: $1.timestamp!)})
            savedPostsVC.posts = sortedPosts
            savedPostsVC.currentUser = currentUser
        } else if segue.identifier == "PresentComments" {
            let commentsVC = segue.destination as! CommentsViewController
            let post = sender as! Post
            commentsVC.post = post
        }
    }
    
    func editProfile() {
        self.performSegue(withIdentifier: "EditProfile", sender: nil)
    }
    
    func pushToPost(dataDict: [String: Any]) {
        performSegue(withIdentifier: "pushToPost", sender: dataDict)
    }
    
    func savedPosts() {
        postService.usersSavedPosts(currentUser: currentUser!) { (posts) in
            self.performSegue(withIdentifier: "ShowSavedPosts", sender: posts)
        }
    }
    
    func listViewMode() {
        postMode = .listView
        DispatchQueue.main.async {
            self.profileCollectionView.reloadData()
        }
    }
    
    func gridViewMode() {
        postMode = .gridView
        DispatchQueue.main.async {
            self.profileCollectionView.reloadData()
        }
    }
    
    func goToComments(_ sender: AnyObject){
        let buttonPosition:CGPoint = sender.convert(CGPoint.zero, to: self.profileCollectionView)
        let indexPath = self.profileCollectionView.indexPathForItem(at: buttonPosition)
        let row = indexPath?.row
        
        performSegue(withIdentifier: "PresentComments", sender: row)
    }
    
    func presentComments(_ sender: UITapGestureRecognizer) {
        if let indexPath = self.profileCollectionView.indexPathForItem(at: sender.location(in: self.profileCollectionView)) {
            let post = posts[indexPath.row]
            performSegue(withIdentifier: "PresentComments", sender: post)
        }
    }
    
    func goToFollowing() {
        if user != nil {
            accountService.fetchFollowing(user: user!) { (users) in
                let storyboard = UIStoryboard(name: "Main", bundle: nil)
                let activityVC = storyboard.instantiateViewController(withIdentifier: "ActivityControl") as! ActivityViewController
                activityVC.users = users
                activityVC.activity = .following
                activityVC.user = self.user!
                self.navigationController?.pushViewController(activityVC, animated: true)
            }
        }
    }
    
    func goToFollowers() {
        if user != nil {
            accountService.fetchFollowers(user: user!) { (users) in
                let storyboard = UIStoryboard(name: "Main", bundle: nil)
                let activityVC = storyboard.instantiateViewController(withIdentifier: "ActivityControl") as! ActivityViewController
                activityVC.users = users
                activityVC.activity = .followers
                activityVC.user = self.user!
                self.navigationController?.pushViewController(activityVC, animated: true)
            }
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
            print("Segue")
            let dataDict: [String: Any] = ["hashtag": hashtag, "posts": posts]
            let storyboard = UIStoryboard(name: "Main", bundle: nil)
            let hashtagController = storyboard.instantiateViewController(withIdentifier: "hashtagController") as! HashtagsViewController
            hashtagController.posts = posts
            hashtagController.hashtag = hashtag
            self.navigationController?.pushViewController(hashtagController, animated: true)
        }
    }
    
    func displayLikesController(_ sender: UITapGestureRecognizer) {
        if let indexPath = self.profileCollectionView.indexPathForItem(at: sender.location(in: self.profileCollectionView)) {
            let post = posts[indexPath.row]
            postService.fetchPostLikes(post: post, completion: { (users) in
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
    }
    
    func mentionPosts() {
        if user != nil {
            postService.usersMentionPosts(username: user!.username!, completion: { (posts) in
                let storyboard = UIStoryboard(name: "Main", bundle: nil)
                let mentionsVC = storyboard.instantiateViewController(withIdentifier: "DisplayMentions") as! MentionsViewController
                mentionsVC.posts = posts
                self.navigationController?.pushViewController(mentionsVC, animated: true)
                print("All posts for user! \(posts)")
            })
        }
    }
    
    func postOptions(_ sender: UITapGestureRecognizer) {
        if let indexPath = self.profileCollectionView.indexPathForItem(at: sender.location(in: self.profileCollectionView)) {
            let post = posts[indexPath.row]
            
            let alert = UIAlertController(title: "Delete post?", message: nil,  preferredStyle: .actionSheet)
            let deleteAction = UIAlertAction(title: "Delete", style: .destructive, handler: { (action) in
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
        }
    }
}

extension ProfilePageViewController: UINavigationBarDelegate {
    func position(for bar: UIBarPositioning) -> UIBarPosition {
        return .topAttached
    }
}

extension ProfilePageViewController: UICollectionViewDataSource {
    func numberOfSections(in collectionView: UICollectionView) -> Int {
        return 3
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        if section == 0 || section == 1 {
            return 1
        }
        
        return posts.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        
        if indexPath.section == 0 {
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "ProfileCellNib", for: indexPath) as! ProfileCellNib
            
            let currentUser = FIRAuth.auth()?.currentUser
            
            let followingView = cell.followingView!
            followingView.isUserInteractionEnabled = true
            let followingTapped = UITapGestureRecognizer(target: self, action: #selector(ProfilePageViewController.goToFollowing))
            followingTapped.numberOfTapsRequired = 1
            followingView.addGestureRecognizer(followingTapped)
            
            let followersView = cell.followersView!
            followersView.isUserInteractionEnabled = true
            let followersTapped = UITapGestureRecognizer(target: self, action: #selector(ProfilePageViewController.goToFollowers))
            followersTapped.numberOfTapsRequired = 1
            followersView.addGestureRecognizer(followersTapped)
            
            let imageView = cell.profilePicture!
            let tapGesture = UITapGestureRecognizer(target: self, action: #selector(ProfilePageViewController.showPhotoMenu))
            tapGesture.numberOfTapsRequired = 1
            imageView.addGestureRecognizer(tapGesture)
            
            let editProfile = cell.viewWithTag(902100) as! UIButton
            editProfile.addTarget(self, action: #selector(ProfilePageViewController.editProfile), for: .touchUpInside)
            
            cell.updatePostCount(count: self.posts.count)
            
            if updatePicture {
                if let newPicture = image, user != nil {
                    cell.updateUserPicture(user: currentUser!, image: newPicture)
                }
            }
            
            if user != nil {
                cell.configure(user: user!)
            }
            
            return cell
        } else if indexPath.section == 1 {
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "ProfileOrganizeCellNib", for: indexPath)
            
            let listView = cell.viewWithTag(702) as! UIImageView
            let listViewTap = UITapGestureRecognizer(target: self, action: #selector(ProfilePageViewController.listViewMode))
            listViewTap.numberOfTapsRequired = 1
            listView.addGestureRecognizer(listViewTap)
            
            let gridView = cell.viewWithTag(709) as! UIImageView
            let gridViewTap = UITapGestureRecognizer(target: self, action: #selector(ProfilePageViewController.gridViewMode))
            gridViewTap.numberOfTapsRequired = 1
            gridView.addGestureRecognizer(gridViewTap)
            
            let savedPicturesButton = cell.viewWithTag(704) as! UIImageView
            let tapGesture = UITapGestureRecognizer(target: self, action: #selector(ProfilePageViewController.savedPosts))
            tapGesture.numberOfTapsRequired = 1
            savedPicturesButton.addGestureRecognizer(tapGesture)
            
            let mentionButton = cell.viewWithTag(703) as! UIImageView
            let mentionGesture = UITapGestureRecognizer(target: self, action: #selector(ProfilePageViewController.mentionPosts))
            mentionGesture.numberOfTapsRequired = 1
            mentionButton.addGestureRecognizer(mentionGesture)
            
            switch postMode {
            case .gridView:
                gridView.image = #imageLiteral(resourceName: "viewoptionone")
                listView.image = #imageLiteral(resourceName: "viewoptiontwo")
            case .listView:
                gridView.image = #imageLiteral(resourceName: "viewoptionone_unselected")
                listView.image = #imageLiteral(resourceName: "viewoptiontwo_selected")
            }
            
            return cell
        } else {
            switch postMode {
            case .gridView:
                let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "ProfilePhotoCell", for: indexPath) as! ProfilePhotoCell
                
                let post = posts[indexPath.row]
                cell.configure(post: post)
                
                return cell
            case .listView:
                let post = posts[indexPath.row]
                
                if let caption = post.caption {
                    let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "PostCellWithCaption", for: indexPath) as! PostCellWithCaption
                    
                    let commentsButton = cell.viewWithTag(2005) as! UIButton
                    commentsButton.addTarget(self, action: #selector(ProfilePageViewController.goToComments(_:)), for: .touchUpInside)
                    
                    let username = user!.username!
                    
                    let tapGesture = UITapGestureRecognizer(target: self, action: #selector(ProfilePageViewController.presentComments(_:)))
                    tapGesture.numberOfTapsRequired = 1
                    cell.captionTextView.addGestureRecognizer(tapGesture)
                    
                    cell.captionTextView.text = "\(username) \(caption)"
                    cell.captionTextView.resolveHashTags()
                    cell.captionTextView.sizeToFit()
                    cell.captionTextView.delegate = self
                    
                    let likesTapped = UITapGestureRecognizer(target: self, action: #selector(ProfilePageViewController.displayLikesController(_:)))
                    likesTapped.numberOfTapsRequired = 1
                    cell.likesLabel.addGestureRecognizer(likesTapped)
                    
                    let optionsTapped = UITapGestureRecognizer(target: self, action: #selector(ProfilePageViewController.postOptions(_:)))
                    optionsTapped.numberOfTapsRequired = 1
                    cell.optionsButton.addGestureRecognizer(optionsTapped)
                    
                    cell.configure(post: post)
                                        
                    return cell
                } else {
                    let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "PostCell", for: indexPath) as! PostCell
                    
                    let commentsButton = cell.viewWithTag(2005) as! UIButton
                    commentsButton.addTarget(self, action: #selector(ProfilePageViewController.goToComments(_:)), for: .touchUpInside)
                    
                    let likesTapped = UITapGestureRecognizer(target: self, action: #selector(ProfilePageViewController.displayLikesController(_:)))
                    likesTapped.numberOfTapsRequired = 1
                    cell.likesLabel.addGestureRecognizer(likesTapped)
                    
                    let optionsTapped = UITapGestureRecognizer(target: self, action: #selector(ProfilePageViewController.postOptions(_:)))
                    optionsTapped.numberOfTapsRequired = 1
                    cell.optionsButton.addGestureRecognizer(optionsTapped)
                    
                    cell.configure(post: post)
                    
                    return cell
                }
            }
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAtIndexPath indexPath: IndexPath) -> CGSize {
        
        if indexPath.section == 0 && indexPath.row == 0 {
            let profileObject = profileCellNib.object(at: 0) as! ProfileCellNib
            
            if user != nil {
                profileObject.configure(biograph: user!.biograph, displayName: user!.name)
                
                let newHeight = profileObject.preferredLayoutSizeFittingSize(targetSize: CGSize(width: self.view.frame.width, height: 0)).height
                
                return CGSize(width: self.view.frame.width, height: newHeight)
            } else {
                return CGSize(width: self.view.frame.width, height: 125)
            }
        } else if indexPath.section == 1 {
            return CGSize(width: view.frame.size.width, height: CGFloat(52))
        } else {
            switch postMode {
            case .gridView:
                let layout = collectionView.collectionViewLayout as! UICollectionViewFlowLayout
                layout.sectionInset = UIEdgeInsets(top: 2, left: 2, bottom: 2, right: 2)
                layout.minimumInteritemSpacing = 02
                layout.minimumLineSpacing = 02
                layout.invalidateLayout()
                
                return CGSize(width: view.frame.size.width / 3 - 4, height: view.frame.size.width / 3 - 4)
            case .listView:
                let postObject = postCellCaptionNib.object(at: 0) as! PostCellWithCaption
                
                let post = posts[indexPath.row]
                if post.caption != nil {
                    postObject.configure(username: user!.username!, caption: post.caption!)
                    let newHeight = postObject.preferredLayoutSizeFittingSize(targetSize: CGSize(width: self.view.frame.width, height: 0)).height
                    print("new height: \(newHeight) received!")
                    return CGSize(width: self.view.frame.width, height: newHeight)
                } else {
                    print("Default Post Height")
                    return CGSize(width: self.view.frame.width, height: 437)
                }
            }
            
        }
        
    }
}

extension ProfilePageViewController: UITextViewDelegate {
    func textView(_ textView: UITextView, shouldInteractWith URL: URL, in characterRange: NSRange, interaction: UITextItemInteraction) -> Bool {
        if let scheme = URL.scheme {
            switch scheme {
            case "hash":
                let hashtag = "#\(URL.absoluteString.components(separatedBy: ":")[1])"
                loadHashtagController(hashtag: hashtag)
            case "mention":
                let username = URL.absoluteString.components(separatedBy: ":")[1]
                loadProfileWithUsername(username: username)
            default:
                print("NOrmal URL")
            }
        }
        
        return false
    }
}

extension ProfilePageViewController: UICollectionViewDelegate {
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        print("Did Select \(indexPath) \(indexPath.row)")
        
        switch postMode {
        case .gridView:
            if indexPath.section == 2 {
                let post = posts[indexPath.row]
                postService.userFromId(id: post.userID!, completion: { (user) in
                    let dataDict: [String: Any] = ["user": user, "post": post]
                    self.pushToPost(dataDict: dataDict)
                })
            }
        case .listView:
            break;
        }
    }
}


extension ProfilePageViewController: UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    func takePhotoWithCamera() {
        let imagePicker = UIImagePickerController()
        imagePicker.sourceType = .camera
        imagePicker.delegate = self
        imagePicker.allowsEditing = true
        present(imagePicker, animated: true, completion: nil)
    }
    
    func photoFromLibrary() {
        let imagePicker = UIImagePickerController()
        imagePicker.sourceType = .photoLibrary
        imagePicker.delegate = self
        imagePicker.allowsEditing = true
        present(imagePicker, animated: true, completion: nil)
    }
    
    func showPhotoMenu() {
        let alertController = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)
        
        let cancelAction = UIAlertAction(title: "Cancel", style: .cancel, handler: nil)
        alertController.addAction(cancelAction)
        
        let takePhotoAction = UIAlertAction(title: "Take Photo with Camera", style: .default) { (alert) in
            self.takePhotoWithCamera()
        }
        alertController.addAction(takePhotoAction)
        
        let photoFromLibrary = UIAlertAction(title: "Pick Photo From Library", style: .default) { (alert) in
            self.photoFromLibrary()
        }
        alertController.addAction(photoFromLibrary)
        
        
        present(alertController, animated: true, completion: nil)
    }
    
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [String : Any]) {
        image = info[UIImagePickerControllerEditedImage] as? UIImage
        
        if let theImage = image {
            show(image: theImage)
        }
        
        dismiss(animated: true, completion: nil)
    }
    
    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        print("CANCEL!")
        dismiss(animated: true, completion: nil)
    }
}
