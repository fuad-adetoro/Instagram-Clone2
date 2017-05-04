//
//  ViewUserProfileViewController.swift
//  Instagram
//
//  Created by apple  on 19/04/2017.
//  Copyright © 2017 Instagram. All rights reserved.
//

import UIKit
import Firebase

class ViewUserProfileViewController: UIViewController {

    @IBOutlet weak var profileCollectionView: UICollectionView!
    
    enum PostMode {
        case gridView
        case listView
    }
    
    var user: User?
    var currentUser = FIRAuth.auth()?.currentUser
    var posts: [Post] = []
    let postService = PostService()
    let accountService = AccountService()
    
    var postMode: PostMode = .gridView
    
    let postCellCaptionNib = Bundle.main.loadNibNamed("PostCellWithCaption", owner: PostCellWithCaption.self, options: nil)! as NSArray
    let profileCellNib = Bundle.main.loadNibNamed("ProfileCellNib", owner: ProfileCellNib.self, options: nil)! as NSArray
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        var cellNib = UINib(nibName: "ProfileCellNib", bundle: nil)
        profileCollectionView.register(cellNib, forCellWithReuseIdentifier: "ProfileCellNib")
        
        cellNib = UINib(nibName: "ProfileOrganizeCellNib", bundle: nil)
        profileCollectionView.register(cellNib, forCellWithReuseIdentifier: "ProfileOrganizeCellNib")
        
        cellNib = UINib(nibName: "ProfilePhotoCell", bundle: nil)
        profileCollectionView.register(cellNib, forCellWithReuseIdentifier: "ProfilePhotoCell")
        
        cellNib = UINib(nibName: "UserProfileOrganizeCellNib", bundle: nil)
        profileCollectionView.register(cellNib, forCellWithReuseIdentifier: "UserProfileOrganizeCellNib")
        
        cellNib = UINib(nibName: "PostCellWithCaption", bundle: nil)
        profileCollectionView.register(cellNib, forCellWithReuseIdentifier: "PostCellWithCaption")
        
        cellNib = UINib(nibName: "PostCell", bundle: nil)
        profileCollectionView.register(cellNib, forCellWithReuseIdentifier: "PostCell")
        
        let refreshCtrl = UIRefreshControl()
        refreshCtrl.tag = 91
        refreshCtrl.addTarget(self, action: #selector(ViewUserProfileViewController.fetchUser) , for: .valueChanged)
        profileCollectionView?.addSubview(refreshCtrl)
        
        fetchUser()
    }
    
    func fetchUser() {
        self.navigationItem.title = user!.username!
        self.postService.fetchPosts(userID: user!.userID!) { (userPosts) in
            let postsSorted = userPosts.sorted(by: {Date(timeIntervalSince1970: $0.timestamp!) > Date(timeIntervalSince1970: $1.timestamp!)})
            self.posts = postsSorted
            if let refreshCtrl = self.view.viewWithTag(91) as? UIRefreshControl {
                refreshCtrl.endRefreshing()
            }
            self.profileCollectionView.reloadData()
        }
    }
    
    func editProfile() {
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        let navController = storyboard.instantiateViewController(withIdentifier: "EditProfile") as! UINavigationController
        let editProfileVC = navController.topViewController as! EditProfileViewController
        let user = FIRAuth.auth()?.currentUser
        editProfileVC.user = user!
        present(navController, animated: true, completion: nil)
    }
    
    func goToPost(dataDict: [String: Any]) {        
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        let profilePostVC = storyboard.instantiateViewController(withIdentifier: "ShowPost") as! ViewProfilePostController
        let post = dataDict["post"] as! Post
        let user = dataDict["user"] as! User
        profilePostVC.post = post
        profilePostVC.user = user
        
        self.navigationController?.pushViewController(profilePostVC, animated: true)
        
        //ShowPost
    }
    
    func goToSavedPosts() {
        postService.usersSavedPosts(currentUser: currentUser!) { (posts) in
            let storyboard = UIStoryboard(name: "Main", bundle: nil)
            let savedPostsVC = storyboard.instantiateViewController(withIdentifier: "DisplaySavedPosts") as! ViewSavedPostsViewController
            let sortedPosts: [Post] = posts.sorted(by: {Date(timeIntervalSince1970: $0.timestamp!) > Date(timeIntervalSince1970: $1.timestamp!)})
            savedPostsVC.posts = sortedPosts
            savedPostsVC.currentUser = self.currentUser
            
            self.navigationController?.pushViewController(savedPostsVC, animated: true)
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
        if let indexPath = self.profileCollectionView.indexPathForItem(at: sender.location(in: self.profileCollectionView)) {
            let post = posts[indexPath.row]
            let storyboard = UIStoryboard(name: "Main", bundle: nil)
            let commentsVC = storyboard.instantiateViewController(withIdentifier: "DisplayComments") as! CommentsViewController
            commentsVC.post = post
            self.navigationController?.pushViewController(commentsVC, animated: true)
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
}

extension ViewUserProfileViewController: UICollectionViewDataSource {
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
            
            cell.updatePostCount(count: self.posts.count)
            
            let followingView = cell.followingView!
            followingView.isUserInteractionEnabled = true
            let followingTapped = UITapGestureRecognizer(target: self, action: #selector(ViewUserProfileViewController.goToFollowing))
            followingTapped.numberOfTapsRequired = 1
            followingView.addGestureRecognizer(followingTapped)
            
            let followersView = cell.followersView!
            followersView.isUserInteractionEnabled = true
            let followersTapped = UITapGestureRecognizer(target: self, action: #selector(ViewUserProfileViewController.goToFollowers))
            followersTapped.numberOfTapsRequired = 1
            followersView.addGestureRecognizer(followersTapped)
            
            if user != nil {
                cell.configure(user: user!)
    
                let editProfile = cell.editProfileButton!
                
                if user!.userID! == currentUser!.uid {
                    editProfile.addTarget(self, action: #selector(ViewUserProfileViewController.editProfile), for: .touchUpInside)
                } else {
                    cell.interactiveButton(user: user!, currentUser: currentUser!)
                }
            }
            
            return cell
        } else if indexPath.section == 1 {
            if user!.userID! != currentUser!.uid {
                let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "UserProfileOrganizeCellNib", for: indexPath)
                
                let listView = cell.viewWithTag(1902) as! UIImageView
                let listViewTap = UITapGestureRecognizer(target: self, action: #selector(ViewUserProfileViewController.listViewMode))
                listViewTap.numberOfTapsRequired = 1
                listView.addGestureRecognizer(listViewTap)
                
                let gridView = cell.viewWithTag(1901) as! UIImageView
                let gridViewTap = UITapGestureRecognizer(target: self, action: #selector(ViewUserProfileViewController.gridViewMode))
                gridViewTap.numberOfTapsRequired = 1
                gridView.addGestureRecognizer(gridViewTap)
                
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
                let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "ProfileOrganizeCellNib", for: indexPath)
                
                let listView = cell.viewWithTag(702) as! UIImageView
                let listViewTap = UITapGestureRecognizer(target: self, action: #selector(ViewUserProfileViewController.listViewMode))
                listViewTap.numberOfTapsRequired = 1
                listView.addGestureRecognizer(listViewTap)
                
                let gridView = cell.viewWithTag(709) as! UIImageView
                let gridViewTap = UITapGestureRecognizer(target: self, action: #selector(ViewUserProfileViewController.gridViewMode))
                gridViewTap.numberOfTapsRequired = 1
                gridView.addGestureRecognizer(gridViewTap)
                
                let savedPicturesButton = cell.viewWithTag(704) as! UIImageView
                let tapGesture = UITapGestureRecognizer(target: self, action: #selector(ViewUserProfileViewController.goToSavedPosts))
                tapGesture.numberOfTapsRequired = 1
                savedPicturesButton.addGestureRecognizer(tapGesture)
                
                switch postMode {
                case .gridView:
                    gridView.image = #imageLiteral(resourceName: "viewoptionone")
                    listView.image = #imageLiteral(resourceName: "viewoptiontwo")
                case .listView:
                    gridView.image = #imageLiteral(resourceName: "viewoptionone_unselected")
                    listView.image = #imageLiteral(resourceName: "viewoptiontwo_selected")
                }
                
                return cell
            }
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
                    commentsButton.addTarget(self, action: #selector(ViewUserProfileViewController.goToComments(_:)), for: .touchUpInside)
                    
                    let username = user!.username!
                    
                    cell.captionTextView.setText(text: "\(username) \(caption)", withHashtagColor: UIColor.blue, andMentionColor: UIColor.blue, andCallback: { (strings, type) in
                        //
                    }, normalFont: UIFont.systemFont(ofSize: 9.0), hashtagFont: UIFont.boldSystemFont(ofSize: 11), mentionFont: UIFont.boldSystemFont(ofSize: 11))
                    cell.captionTextView.sizeToFit()
                    
                    let tapGesture = UITapGestureRecognizer(target: self, action: #selector(ViewUserProfileViewController.goToComments(_:)))
                    cell.captionTextView.addGestureRecognizer(tapGesture)
                    
                    cell.configure(post: post)
                    
                    return cell
                } else {
                    let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "PostCell", for: indexPath) as! PostCell
                    
                    let commentsButton = cell.viewWithTag(2005) as! UIButton
                    commentsButton.addTarget(self, action: #selector(ViewUserProfileViewController.goToComments(_:)), for: .touchUpInside)
                                    
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
                    //postObject.configure(post: post)
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

extension ViewUserProfileViewController: UICollectionViewDelegate {
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        print("Did Select \(indexPath) \(indexPath.row)")
        
        if indexPath.section == 2 {
            let post = posts[indexPath.row]
            postService.userFromId(id: post.userID!, completion: { (user) in
                let dataDict: [String: Any] = ["user": user, "post": post]
                self.goToPost(dataDict: dataDict)
            })
        }
    }
}