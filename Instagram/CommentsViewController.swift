//
//  CommentsViewController.swift
//  Instagram Clone
//
//  Created by Fuad on 08/04/2017.
//  Copyright © 2017 FuadAdetoro. All rights reserved.
//

import UIKit
import Firebase

class CommentsViewController: UIViewController {

    let postService = PostService()
    let authService = AuthService()
    let accountService = AccountService()
    
    var downloadTask: URLSessionDownloadTask!
    
    @IBOutlet weak var commentTextField: UITextField!
    
    var post: Post!
    let currentUser = FIRAuth.auth()?.currentUser
    var comments: [Comments] = []
    
    @IBOutlet weak var postOutlet: UIButton!
    @IBOutlet weak var tableView: UITableView!
    
    @IBAction func postComment(_ sender: Any) {
        // Comment posted
        postService.postComment(post: post!, comment: commentTextField.text!, user: currentUser!)
    }
    
    func fetchComments() {
        // Fetching comments for post
        postService.fetchComments(post: post!) { (comments) in
            // Sorting the comments based of the comment's post timestamp
            let sortedComments = comments.sorted(by: {Date(timeIntervalSince1970: $0.timestamp!) > Date(timeIntervalSince1970: $1.timestamp!)})
            self.comments = sortedComments
            self.tableView.reloadData()
        }
    }
    
    var keyboardHeight: CGFloat = 253
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Increased Cache capacity to store images up to 500MB
        let memoryCapacity = 500 * 1024 * 1024
        let diskCapacity = 500 * 1024 * 1024
        let cache = URLCache(memoryCapacity: memoryCapacity, diskCapacity: diskCapacity, diskPath: nil)
        URLCache.shared = cache

        // If the table view doesn't have enough rows remove the extra footer lines if the rows don't exist
        tableView.tableFooterView = UIView()
        
        NotificationCenter.default.addObserver(self, selector: #selector(CommentsViewController.keyboardWillShow(_:)), name: .UIKeyboardWillShow, object: nil)
        
        fetchComments()
    }
    
    func keyboardWillShow(_ notification: NSNotification) {
        // When the keyboard is shown we will determine the height based of the keyboard size, we will then add that to a local variable which will be used to animate the view up.
        if let keyboardSize = (notification.userInfo?[UIKeyboardFrameEndUserInfoKey] as? NSValue)?.cgRectValue {
            self.keyboardHeight = keyboardSize.height
            
            self.tableView.rowHeight = UITableViewAutomaticDimension
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
            print("Segue")
            let dataDict: [String: Any] = ["hashtag": hashtag, "posts": posts]
            let storyboard = UIStoryboard(name: "Main", bundle: nil)
            let hashtagController = storyboard.instantiateViewController(withIdentifier: "hashtagController") as! HashtagsViewController
            hashtagController.posts = posts
            hashtagController.hashtag = hashtag
            self.navigationController?.pushViewController(hashtagController, animated: true)
        }
    }
}

extension CommentsViewController: UITextFieldDelegate {
    func textFieldDidBeginEditing(_ textField: UITextField) {
        textField.becomeFirstResponder()
        // Animate the view up when the keyboard is shown by the keyboardHeight
        animateViewUp(by: keyboardHeight)
    }
    
    func textFieldDidEndEditing(_ textField: UITextField) {
        textField.resignFirstResponder()
        // Animate the view down by the keyboard height when the keyboard is being dimissed
        animateViewDown(by: keyboardHeight)
    }
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        return true
    }
}

extension CommentsViewController: UITableViewDataSource {
    func numberOfSections(in tableView: UITableView) -> Int {
        return 2
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if section == 0 {
            if post!.caption != nil {
                return 1
            } else {
                return 0
            }
        } else {
            return comments.count
        }
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        if indexPath.section == 0 {
            let cell = tableView.dequeueReusableCell(withIdentifier: "CommentsCaption", for: indexPath)
        
            let profilePicture = cell.viewWithTag(401) as! UIImageView
            profilePicture.layer.masksToBounds = true
            profilePicture.layer.cornerRadius = profilePicture.frame.width / 2
            
            let captionTextView = cell.viewWithTag(402) as! UITextView
            captionTextView.textContainer.lineFragmentPadding = 0
            captionTextView.textContainerInset = UIEdgeInsets.zero
            captionTextView.delegate = self
            captionTextView.resolveHashTags()
            
            authService.userFromId(id: post.userID!, completion: { (user) in
                let username = user.username!
                let caption = self.post.caption!
                captionTextView.text = "\(username) \(caption)"
                if let photoURL = user.photoURL, let url = URL(string: photoURL) {
                    self.downloadTask = profilePicture.loadImage(url: url)
                }
            })
            
            captionTextView.sizeToFit()
            
            return cell
        } else {
            let cell = tableView.dequeueReusableCell(withIdentifier: "CommentsComment", for: indexPath)
            
            let comment = comments[indexPath.row]
            
            let profilePicture = cell.viewWithTag(501) as! UIImageView
            profilePicture.layer.masksToBounds = true
            profilePicture.layer.cornerRadius = profilePicture.frame.width / 2
            
            let messageView = cell.viewWithTag(502) as! UITextView
            messageView.textContainer.lineFragmentPadding = 0
            messageView.textContainerInset = UIEdgeInsets.zero
            messageView.delegate = self
            messageView.resolveHashTags()
            
            let date = Date(timeIntervalSince1970: comment.timestamp!)
            let timeLabel = cell.viewWithTag(503) as! UILabel
            timeLabel.text = date.timeSinceComment()
            
            authService.userFromId(id: comment.userID!, completion: { (user) in
                let username = user.username!
                let message = comment.comment!
                DispatchQueue.main.async {
                    messageView.text = "\(username) \(message)"
                    messageView.sizeToFit()
                }
                if let photoURL = user.photoURL, let url = URL(string: photoURL) {
                    self.downloadTask = profilePicture.loadImage(url: url)
                }
            })
            
            return cell
        }
    }
    
    func tableView(tableView: UITableView, heightForRowAtIndexPath indexPath: NSIndexPath) -> CGFloat {
        if indexPath.section == 0 {
            return UITableViewAutomaticDimension
        } else {
            //let postObject = commentsCaption.object(at: 0) as! CommentsCell
            
            //let newHeight = postObject.contentView.frame.height
            
            let newCommentView = CommentsCell.init(style: .default, reuseIdentifier: "CommentsComments")
            let comment = comments[indexPath.row]
            newCommentView.captionTextView.text = "\(comment)"
        
            let newHeight = newCommentView.contentView.frame.height
            
            if newHeight == 0 {
                return UITableViewAutomaticDimension
            } else {
                return newHeight + 15
            }
        }
    }
}

extension CommentsViewController : UITextViewDelegate {
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

class CommentsCell: UITableViewCell {
    
    @IBOutlet weak var profilePictureView: UIImageView!
    @IBOutlet weak var captionTextView: UITextView!
    @IBOutlet weak var timePostedLabel: UILabel!
    
    @IBAction func replyToComment(_ sender: Any) {
        
    }
        
    override func awakeFromNib() {
        // Awake
    }
}
