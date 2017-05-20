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
    // loadImage loads a image using a URL and URLSessionDownloadTask
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
