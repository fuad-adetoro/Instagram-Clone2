//
//  UITextViewExtension.swift
//  Instagram
//
//  Created by apple  on 01/05/2017.
//  Copyright © 2017 Instagram. All rights reserved.
//

import UIKit


func += <KeyType, ValueType> (left: inout Dictionary<KeyType, ValueType>, right: Dictionary<KeyType, ValueType>) {
    for (k, v) in right {
        left.updateValue(v, forKey: k)
    }
}

extension String {
    func NSRangeFromRange(range: Range<String.Index>) -> NSRange {
        let utf16view = self.utf16
        let from = String.UTF16View.Index(range.lowerBound, within: utf16view)
        //let from = String.UTF16View.Index(range.lowerBound, within: utf16view)
        let to = String.UTF16View.Index(range.upperBound, within: utf16view)
        
        return NSMakeRange(utf16view.startIndex.distance(to: from), from.distance(to: to))
    }
    
    mutating func dropTrailingNonAlphaNumericCharacters() {
        let nonAlphaNumericCharacters = NSCharacterSet.alphanumerics.inverted
        let charactersArray = components(separatedBy: nonAlphaNumericCharacters)
        
        if let first = charactersArray.first {
            self = first
        }
    }
}

extension UITextView {
    
    public func resolveHashTags(possibleUserDisplayNames:[String]? = nil) {
        
        let schemeMap = [
            "#":"hash",
            "@":"mention"
        ]
        
        // Separate the string into individual words.
        // Whitespace is used as the word boundary.
        // You might see word boundaries at special characters, like before a period.
        // But we need to be careful to retain the # or @ characters.
        let words = self.text.components(separatedBy: .whitespaces)
        let attributedString = attributedText.mutableCopy() as! NSMutableAttributedString
        
        // keep track of where we are as we interate through the string.
        // otherwise, a string like "#test #test" will only highlight the first one.
        let bookmark = text.startIndex
        
        // Iterate over each word.
        // So far each word will look like:
        // - I
        // - visited
        // - #123abc.go!
        // The last word is a hashtag of #123abc
        // Use the following hashtag rules:
        // - Include the hashtag # in the URL
        // - Only include alphanumeric characters.  Special chars and anything after are chopped off.
        // - Hashtags can start with numbers.  But the whole thing can't be a number (#123abc is ok, #123 is not)
        
        for word in words {
            var scheme: String? = nil
            
            if word.hasPrefix("#") {
                scheme = schemeMap["#"]
            } else if word.hasPrefix("@") {
                scheme = schemeMap["@"]
            }
            
            // Drop the # or @
            var wordWithTagRemoved = String(word.characters.dropFirst())
            
            // Drop any trailing punctuation
            wordWithTagRemoved.dropTrailingNonAlphaNumericCharacters()
            
            // Make sure we still have a valid word (i.e. not not just "#" or "@" by itself and not @100
            guard let schemeMatch = scheme, Int(wordWithTagRemoved) == nil && !wordWithTagRemoved.isEmpty else {
                continue
            }
            
            let remainingRange = Range(bookmark..<text.endIndex)
            
            
            // URL syntax is http://123abc
            
            // Replace custom scheme with something like hash://123abc
            // URLs actually don't need the forward slashes, so it becomes hash:123abc
            // Custom scheme for @mentions looks like mention:123abc
            // As with any URL, the string will have a blue color and is clickable
            
            if let matchRange = text.range(of: word, options: .literal, range: remainingRange), let escapedString = wordWithTagRemoved.addingPercentEncoding(withAllowedCharacters: .urlHostAllowed) {
                attributedString.addAttribute(NSLinkAttributeName, value: "\(schemeMatch):\(escapedString)", range: text.NSRangeFromRange(range: matchRange))
                print("\(schemeMatch) \(escapedString) \(matchRange)")
            }
        }
        
        self.attributedText = attributedString
    }
}

enum wordType {
    case hashtag
    case mention
    //case comment
}

extension UITextView {
    func setText(text: String, withHashtagColor hashtagColor: UIColor, andMentionColor mentionColor: UIColor, andCallback callback: @escaping (String, wordType) -> Void, normalFont: UIFont, hashtagFont: UIFont, mentionFont: UIFont) {
        let attrString: NSMutableAttributedString? = NSMutableAttributedString(string: text)
        let textString: NSString? = NSString(string: text)
        
        attrString?.addAttribute(NSForegroundColorAttributeName, value: UIColor.black, range: NSRange(location: 0, length: (textString?.length)!))
        
        setAttrWithName(attrName: "Hashtag", wordPrefix: "#", color: hashtagColor, text: text, font: hashtagFont, attrString: attrString, textString: textString)
        setAttrWithName(attrName: "Mention", wordPrefix: "@", color: mentionColor, text: text, font: mentionFont, attrString: attrString, textString: textString)
        setUsernameColor(color: UIColor.black, text: text, font: mentionFont, attrString: attrString, textString: textString)
        
        let tapper = UITapGestureRecognizer(target: self, action: nil)
        addGestureRecognizer(tapper)
    }
    
    func setAttrWithName(attrName: String, wordPrefix: String, color: UIColor, text: String, font: UIFont, attrString: NSMutableAttributedString?, textString: NSString?) {
        
        // Words will be seperated by space " "
        var words = text.components(separatedBy: " ")
        words.append(contentsOf: text.components(separatedBy: "\n"))
        
        for word in words.filter({$0.hasPrefix(wordPrefix)}) {
            let range = textString!.range(of: word)
            attrString!.addAttribute(NSForegroundColorAttributeName, value: color, range: range)
            attrString!.addAttribute(attrName, value: 1, range: range)
            attrString!.addAttribute("Clickable", value: 1, range: range)
            attrString!.addAttribute(NSFontAttributeName, value: font, range: range)
        }
        
        self.attributedText = attrString
    }
    
    func setUsernameColor(color: UIColor, text: String, font: UIFont, attrString: NSMutableAttributedString?, textString: NSString?) {
        
        var words = text.components(separatedBy: " ")
        
        let username = words[0]
        let range = textString!.range(of: username)
        attrString!.addAttribute(NSFontAttributeName, value: font, range: range)
        attrString!.addAttribute(NSForegroundColorAttributeName, value: color, range: range)
        
        self.attributedText = attrString
    }
    
    /*func tapRecognized(tapGesture: UITapGestureRecognizer) {
        var callBack: ((String, wordType) -> Void)?
        var wordString: String?         // The String value of the word to pass into callback function
        var char: NSAttributedString!   //The character the user clicks on. It is non optional because if the user clicks on nothing, char will be a space or " "
        var word: NSAttributedString?   //The word the user clicks on
        var isHashtag: AnyObject?
        var isAtMention: AnyObject?
        
        // Gets the range of the character at the place the user taps
        let point = tapGesture.location(in: self)
        let charPosition = closestPosition(to: point)
        let charRange = tokenizer.rangeEnclosingPosition(charPosition!, with: .character, inDirection: 1)
        
        //Checks if the user has tapped on a character.
        if charRange != nil {
            let location = offset(from: beginningOfDocument, to: charRange!.start)
            let length = offset(from: charRange!.start, to: charRange!.end)
            let attrRange = NSMakeRange(location, length)
            char = attributedText.attributedSubstring(from: attrRange)
            
            //If the user has not clicked on anything, exit the function
            if char.string == " " {
                print("User clicked on nothing")
                return
            }
            
            // Checks the character's attribute, if any
            isHashtag = char?.attribute("Hashtag", at: 0, longestEffectiveRange: nil, in: NSMakeRange(0, char!.length)) as AnyObject?
            isAtMention = char?.attribute("Mention", at: 0, longestEffectiveRange: nil, in: NSMakeRange(0, char!.length)) as AnyObject?
        }
        
        // Gets the range of the word at the place user taps
        let wordRange = tokenizer.rangeEnclosingPosition(charPosition!, with: .word, inDirection: 1)
        
        /*
         Check if wordRange is nil or not. The wordRange is nil if:
         1. The User clicks on the "#" or "@"
         2. The User has not clicked on anything. We already checked whether or not the user clicks on nothing so 1 is the only possibility
         */
        if wordRange != nil{
            // Get the word. This will not work if the char is "#" or "@" ie, if the user clicked on the # or @ in front of the word
            let wordLocation = offset(from: beginningOfDocument, to: wordRange!.start)
            let wordLength = offset(from: wordRange!.start, to: wordRange!.end)
            let wordAttrRange = NSMakeRange(wordLocation, wordLength)
            word = attributedText.attributedSubstring(from: wordAttrRange)
            wordString = word!.string
        }else{
            /*
             Because the user has clicked on the @ or # in front of the word, word will be nil as
             tokenizer.rangeEnclosingPosition(charPosition!, with: .word, inDirection: 1) does not work with special characters.
             What I am doing here is modifying the x position of the point the user taps the screen. Moving it to the right by about 12 points will move the point where we want to detect for a word, ie to the right of the # or @ symbol and onto the word's text
             */
            var modifiedPoint = point
            modifiedPoint.x += 12
            let modifiedPosition = closestPosition(to: modifiedPoint)
            let modifedWordRange = tokenizer.rangeEnclosingPosition(modifiedPosition!, with: .word, inDirection: 1)
            if modifedWordRange != nil{
                let wordLocation = offset(from: beginningOfDocument, to: modifedWordRange!.start)
                let wordLength = offset(from: modifedWordRange!.start, to: modifedWordRange!.end)
                let wordAttrRange = NSMakeRange(wordLocation, wordLength)
                word = attributedText.attributedSubstring(from: wordAttrRange)
                wordString = word!.string
            }
        }
        
        if let stringToPass = wordString{
            // Runs callback function if word is a Hashtag or Mention
            if isHashtag != nil && callBack != nil {
                callBack!(stringToPass, wordType.hashtag)
            } else if isAtMention != nil && callBack != nil {
                callBack!(stringToPass, wordType.mention)
            }
        }
    }*/
}
