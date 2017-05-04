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
    
    @IBOutlet weak var collectionView: UICollectionView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        var cellNib = UINib(nibName: "PostCell", bundle: nil)
        collectionView.register(cellNib, forCellWithReuseIdentifier: "PostCell")
        
        cellNib = UINib(nibName: "PostCellWithCaption", bundle: nil)
        collectionView.register(cellNib, forCellWithReuseIdentifier: "PostCellWithCaption")
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "DisplayComments" {
            let commentsVC = segue.destination as! CommentsViewController
            commentsVC.post = post!
        }
    }
    
    func goToComments(){
        performSegue(withIdentifier: "DisplayComments", sender: nil)
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
        if post!.caption != nil {
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "PostCellWithCaption", for: indexPath) as! PostCellWithCaption
            
            let commentsButton = cell.viewWithTag(2005) as! UIButton
            commentsButton.addTarget(self, action: #selector(ViewProfilePostController.goToComments), for: .touchUpInside)
            
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
}

extension ViewProfilePostController: UINavigationBarDelegate {
    func position(for bar: UIBarPositioning) -> UIBarPosition {
        return .topAttached
    }
}
