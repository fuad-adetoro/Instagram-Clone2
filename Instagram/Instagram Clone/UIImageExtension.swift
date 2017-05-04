//
//  UIImageExtension.swift
//  Instagram Clone
//
//  Created by Fuad on 09/04/2017.
//  Copyright © 2017 FuadAdetoro. All rights reserved.
//

import UIKit
import Firebase

extension UIImageView {
    func loadImage(url: URL) -> URLSessionDownloadTask {
        let session = URLSession.shared
        
        let downloadTask = session.downloadTask(with: url) { [weak self] (url, response, error) in
            if error == nil, let url = url, let data = try? Data(contentsOf: url), let image = UIImage(data: data) {
                DispatchQueue.main.async {
                    if let strongSelf = self {
                        strongSelf.image = image
                    }
                }
            }
        }
        
        downloadTask.resume()
        return downloadTask
    }
}

/*
 
 if let profilePicture = user.photoURL {
 storageRef.reference(forURL: profilePicture).data(withMaxSize: 1 * 1024 * 1024, completion: { (imgData, error) in
 if error == nil {
 if let image = imgData {
 DispatchQueue.main.async {
 self.profilePicture.image = UIImage(data: image)
 }
 }
 } else {
 print(error?.localizedDescription)
 }
 })
 }
 
 */
