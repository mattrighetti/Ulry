//
//  +NSMutableAttributedString.swift
//  Ulry
//
//  Created by Mattia Righetti on 2/1/22.
//  Copyright © 2022 Mattia Righetti. All rights reserved.
//

import UIKit

extension NSMutableAttributedString {
    convenience init(coloredStrings: [(String, UIColor)], separator: String? = " ") {
        let text = coloredStrings.map(\.0).sorted(by: { $0 <= $1 }).joined(separator: separator!) as String
        let attributedText = NSMutableAttributedString(string: text)
        
        for val in coloredStrings {
            let range = (text as NSString).range(of: val.0)
            attributedText.addAttribute(.foregroundColor, value: val.1, range: range)
        }
        
        self.init(attributedString: attributedText)
    }
}
