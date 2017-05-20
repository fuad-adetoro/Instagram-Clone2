//
//  StringExtension.swift
//  Instagram Clone
//
//  Created by Fuad on 03/04/2017.
//  Copyright © 2017 FuadAdetoro. All rights reserved.
//

import UIKit

extension String {
    // Checking if the String to see if it can be convertibable to a Integer
    var canConvertToInt: Int? {
        let canConvert = Int(self)
        return canConvert
    }
}
