//
//  Likers.swift
//  Instagram Clone
//
//  Created by Fuad on 31/03/2017.
//  Copyright © 2017 FuadAdetoro. All rights reserved.
//

import UIKit
import Firebase

class Likers {
    var likers: Int?
    
    init(snapshot: FIRDataSnapshot) {
        likers = (snapshot.value as! NSDictionary)["likers"] as? Int
    }
}
