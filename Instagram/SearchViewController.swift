//
//  TempSearchViewController.swift
//  Instagram
//
//  Created by apple  on 10/05/2017.
//  Copyright © 2017 Instagram. All rights reserved.
//

import UIKit

class SearchViewController: UIViewController {

    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var searchBar: UISearchBar!
    let accountService = AccountService()
    var users: [User] = []
    var downloadTask: URLSessionDownloadTask!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        createSearchBar()
        
        tableView.tableFooterView = UIView()
        tableView.estimatedRowHeight = 52
        tableView.rowHeight = UITableViewAutomaticDimension
    }
    
    func createSearchBar() {
        let searchBar = UISearchBar()
        searchBar.showsCancelButton = false
        searchBar.delegate = self
        searchBar.placeholder = "Search"
        
        self.navigationItem.titleView = searchBar
    }
    
    
    func search(searchText: String) {
        accountService.searchUsers(searchText: searchText) { (foundUsers) in
            self.users = foundUsers
            self.tableView.reloadData()
        }
    }
}

extension SearchViewController: UISearchBarDelegate {
    func position(for bar: UIBarPositioning) -> UIBarPosition {
        return .topAttached
    }
    
    func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
        search(searchText: searchBar.text!)
    }
}

extension SearchViewController: UITableViewDataSource {
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return users.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "searchResult", for: indexPath)
        
        let profilePicture = cell.viewWithTag(312) as! UIImageView
        let usernameField = cell.viewWithTag(313) as! UILabel
        let nameField = cell.viewWithTag(314) as! UILabel
        
        profilePicture.layer.masksToBounds = true
        profilePicture.layer.cornerRadius = profilePicture.frame.width / 2
        
        let user = users[indexPath.row]
        
        if let photoURL = user.photoURL, let url = URL(string: photoURL) {
            self.downloadTask = profilePicture.loadImage(url: url)
        }
        
        print("blah: \(user.username!)")
        
        usernameField.text = user.username
        
        if let name = user.name {
            nameField.isHidden = false
            nameField.text = name
        } else {
            nameField.isHidden = true
        }
        
        return cell
    }
}

extension SearchViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let user = users[indexPath.row]
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        let viewUserProfileVC = storyboard.instantiateViewController(withIdentifier: "ViewUserProfile") as! ViewUserProfileViewController
        viewUserProfileVC.user = user
        
        self.navigationController?.pushViewController(viewUserProfileVC, animated: true)
        print("Selected: \(indexPath.row)")
    }
}


