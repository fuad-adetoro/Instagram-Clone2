//
//  UITextViewExtension.swift
//  Instagram
//
//  Created by apple  on 01/05/2017.
//  Copyright © 2017 Instagram. All rights reserved.
//

import UIKit

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
                    attrString.addAttribute(NSFontAttributeName, value: UIFont.boldSystemFont(ofSize: 12), range: matchRange)
                }
            } else if word.hasPrefix("@") {
                let matchRange:NSRange = nsText.range(of: word as String)
                var stringifiedWord:String = word as String
                
                stringifiedWord = String(stringifiedWord.characters.dropFirst())
                
                let digits = NSCharacterSet.decimalDigits
                
                if let numbersExist = stringifiedWord.rangeOfCharacter(from: digits) {
                    // do nothing
                } else {
                    attrString.addAttribute(NSLinkAttributeName, value: "mention:\(stringifiedWord)", range: matchRange)
                    attrString.addAttribute(NSFontAttributeName, value: UIFont.boldSystemFont(ofSize: 12), range: matchRange)
                }
            }
        }
        
        let username = words[0]
        let usernameRange: NSRange = nsText.range(of: username as String)
        
        attrString.addAttribute(NSLinkAttributeName, value: "username:\(username)", range: usernameRange)
        attrString.addAttribute(NSFontAttributeName, value: UIFont.boldSystemFont(ofSize: 12), range: usernameRange)
        
        self.linkTextAttributes = [NSForegroundColorAttributeName: UIColor.black]
        
        self.attributedText = attrString
    }
    
}
