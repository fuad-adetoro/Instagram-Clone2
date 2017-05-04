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
    
    let postCellCaptionNib = Bundle.main.loadNibNamed("PostCellWithCaption", owner: PostCellWithCaption.self, options: nil)! as NSArray
    
    override func viewDidLoad() {
        super.viewDidLoad()
                
        var cellNib = UINib(nibName: "PostCell", bundle: nil)
        profileCollectionView.register(cellNib, forCellWithReuseIdentifier: "PostCell")
        
        cellNib = UINib(nibName: "PostCellWithCaption", bundle: nil)
        profileCollectionView.register(cellNib, forCellWithReuseIdentifier: "PostCellWithCaption")
        
        self.navigationItem.titleView = UIImageView(image: #imageLiteral(resourceName: "homelogo"))
        
        fetchPosts()
        
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
    
    func myMethodToHandleTap(_ sender: UITapGestureRecognizer) {
        let myTextView = sender.view as! UITextView
        let text = myTextView.text!
        let username = text.components(separatedBy: " ").first!
        let layoutManager = myTextView.layoutManager
        
        // location of tap in myTextView coordinates and taking the inset into account
        var location = sender.location(in: myTextView)
        location.x -= myTextView.textContainerInset.left;
        location.y -= myTextView.textContainerInset.top;
        print("Location: \(location)")
        
        // character index at tap location
        let characterIndex = layoutManager.characterIndex(for: location, in: myTextView.textContainer, fractionOfDistanceBetweenInsertionPoints: nil)
        
        print("charIndex: \(characterIndex)")
        
        // if index is valid then do something.
        if characterIndex < myTextView.textStorage.length {
            var range = NSRange(location: 0, length: 0)
            if let idval = myTextView.attributedText.attribute("idnum", at: characterIndex, effectiveRange: &range) {
                //let tappedPhrase = (myTextView.attributedText.string as NSString).substring(with: idval)
                print("range.location = \(range.location)")
                print("range.length = \(range.length)")
                print("Idval: \(idval)")
            }
            
            
            print("TextView: \(myTextView.textStorage.length)")
            if characterIndex <= username.characters.count {
                loadProfileWithUsername(username: username)
            } else {
                let storyboard = UIStoryboard(name: "Main", bundle: nil)
                let commentsVC = storyboard.instantiateViewController(withIdentifier: "DisplayComments") as! CommentsViewController
                if let indexPath = self.profileCollectionView.indexPathForItem(at: sender.location(in: self.profileCollectionView)) {
                    let post = posts[indexPath.row]
                    commentsVC.post = post
                    self.navigationController?.pushViewController(commentsVC, animated: true)
                }
            }
        }
    }
    
    func loadProfileWithUsername(username: String) {
        accountService.fetchUserWithUsername(username: username) { (user) in
            self.performSegue(withIdentifier: "ViewUserProfile", sender: user)
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
            
            /*cell.captionTextView.setText(text: "\(username) \(caption)", withHashtagColor: UIColor.blue, andMentionColor: UIColor.blue, andCallback: { (strings, type) in
                //
            }, normalFont: UIFont.systemFont(ofSize: 9.0), hashtagFont: UIFont.boldSystemFont(ofSize: 11), mentionFont: UIFont.boldSystemFont(ofSize: 11))*/
            cell.captionTextView.text = "\(username) \(caption)"
            cell.captionTextView.resolveHashTags()
            cell.captionTextView.sizeToFit()
            
            cell.captionTextView.delegate = self
            
            // Add tap gesture recognizer to Text View
            //let tap = UITapGestureRecognizer(target: self, action: #selector(HomeViewController.myMethodToHandleTap(_:)))
            //tap.numberOfTapsRequired = 1
            //cell.captionTextView.addGestureRecognizer(tap)
            
            let likesTapped = UITapGestureRecognizer(target: self, action: #selector(HomeViewController.displayLikesController))
            likesTapped.numberOfTapsRequired = 1
            cell.likesLabel.addGestureRecognizer(likesTapped)
            
            cell.contentView.frame = cell.bounds
            cell.contentView.autoresizingMask = [.flexibleHeight]
            
            return cell
        } else {
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "PostCell", for: indexPath) as! PostCell
            
            let commentsButton = cell.viewWithTag(2005) as! UIButton
            commentsButton.addTarget(self, action: #selector(HomeViewController.goToComments(_:)), for: .touchUpInside)
                        
            cell.usernameLabel.addTarget(self, action: #selector(HomeViewController.goToProfile(_:)), for: .touchUpInside)
            
            cell.configure(post: post)
            
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
    func showClickAlert(tagType: String, payload: String) {
        let alertView = UIAlertController(title: tagType, message: payload, preferredStyle: .alert)
        let action = UIAlertAction(title: "OK", style: .default, handler: nil)
        alertView.addAction(action)
        present(alertView, animated: true, completion: nil)
    }
    
    func textView(_ textView: UITextView, shouldInteractWith URL: URL, in characterRange: NSRange, interaction: UITextItemInteraction) -> Bool {
        if let scheme = URL.scheme {
            switch scheme {
            case "hash":
                print("Hashtag")
            case "mention":
                print("Mention")
            default:
                print("NOrmal URL")
            }
        }
        
        return true
    }
}

extension UITextView {
    
    func resolveHashTags(){
        
        // turn string in to NSString
        let nsText:NSString = self.text! as NSString!
        
        // this needs to be an array of NSString.  String does not work.
        let words: [NSString] = nsText.components(separatedBy: " ") as [NSString]
        
        let attrs: [String: Any] = [:]
        
        let attrString = NSMutableAttributedString(string: nsText as String, attributes: attrs)
        
        // tag each word if it has a hashtag
        for word in words {
            
            // found a word that is prepended by a hashtag!
            // homework for you: implement @mentions here too.
            if word.hasPrefix("#") {
                
                // a range is the character position, followed by how many characters are in the word.
                // we need this because we staple the "href" to this range.
                let matchRange:NSRange = nsText.range(of: word as String)
                
                // convert the word from NSString to String
                // this allows us to call "dropFirst" to remove the hashtag
                var stringifiedWord:String = word as String
                
                // drop the hashtag
                stringifiedWord = String(stringifiedWord.characters.dropFirst())
                
                // check to see if the hashtag has numbers.
                // ribl is "#1" shouldn't be considered a hashtag.
                let digits = NSCharacterSet.decimalDigits
                
                if let numbersExist = stringifiedWord.rangeOfCharacter(from: digits) {
                    // hashtag contains a number, like "#1" or "@1"
                    // so don't make it clickable
                } else {
                    self.tintColor = UIColor.blue
                    // set a link for when the user clicks on this word.
                    // it's not enough to use the word "hash", but you need the url scheme syntax "hash://"
                    // note:  since it's a URL now, the color is set to the project's tint color
                    attrString.addAttribute(NSLinkAttributeName, value: "hash:\(stringifiedWord)", range: matchRange)
                }
            }
        }
        
        self.attributedText = attrString
    }
    
}
