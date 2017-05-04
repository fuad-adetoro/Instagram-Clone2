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
    
    var downloadTask: URLSessionDownloadTask!
    
    @IBOutlet weak var commentTextField: UITextField!
    
    var post: Post!
    let currentUser = FIRAuth.auth()?.currentUser
    var comments: [Comments] = []
    
    @IBOutlet weak var postOutlet: UIButton!
    @IBOutlet weak var tableView: UITableView!
    
    @IBAction func postComment(_ sender: Any) {
        postService.postComment(post: post!, comment: commentTextField.text!, user: currentUser!)
    }
    
    func fetchComments() {
        postService.fetchComments(post: post!) { (comments) in
            let sortedComments = comments.sorted(by: {Date(timeIntervalSince1970: $0.timestamp!) > Date(timeIntervalSince1970: $1.timestamp!)})
            self.comments = sortedComments
            self.tableView.reloadData()
        }
    }
    
    var keyboardHeight: CGFloat = 253
    
    override func viewDidLoad() {
        super.viewDidLoad()

        tableView.rowHeight = UITableViewAutomaticDimension
        tableView.estimatedRowHeight = 80
        
        NotificationCenter.default.addObserver(self, selector: #selector(CommentsViewController.keyboardWillShow(_:)), name: .UIKeyboardWillShow, object: nil)
        
        fetchComments()
    }
    
    func keyboardWillShow(_ notification: NSNotification) {
        if let keyboardSize = (notification.userInfo?[UIKeyboardFrameEndUserInfoKey] as? NSValue)?.cgRectValue {
            self.keyboardHeight = keyboardSize.height
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
}

extension CommentsViewController: UITextFieldDelegate {
    func textFieldDidBeginEditing(_ textField: UITextField) {
        textField.becomeFirstResponder()
        animateViewUp(by: keyboardHeight)
    }
    
    func textFieldDidEndEditing(_ textField: UITextField) {
        textField.resignFirstResponder()
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
            
            let date = Date(timeIntervalSince1970: comment.timestamp!)
            let timeLabel = cell.viewWithTag(503) as! UILabel
            timeLabel.text = date.timeSinceComment()
            
            authService.userFromId(id: comment.userID!, completion: { (user) in
                let username = user.username!
                let message = comment.comment!
                messageView.text = "\(username) \(message)"
                messageView.sizeToFit()
                if let photoURL = user.photoURL, let url = URL(string: photoURL) {
                    self.downloadTask = profilePicture.loadImage(url: url)
                }
            })
            
            return cell
        }
    }
}
