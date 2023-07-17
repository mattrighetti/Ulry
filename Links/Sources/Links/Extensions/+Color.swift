//
//  File.swift
//  
//
//  Created by Matt on 07/11/2022.
//  Copyright © 2022 Mattia Righetti. All rights reserved.
//

import SwiftUI

extension Color {
    public static func randomHexColorCode() -> String {
        let a = ["1","2","3","4","5","6","7","8","9","a","b","c","d","e","f"];
        return
            "#"
            .appending(a[Int(arc4random_uniform(15))])
            .appending(a[Int(arc4random_uniform(15))])
            .appending(a[Int(arc4random_uniform(15))])
            .appending(a[Int(arc4random_uniform(15))])
            .appending(a[Int(arc4random_uniform(15))])
            .appending(a[Int(arc4random_uniform(15))])
    }

    // MARK: - Initializers
    init(decimalRed red: Double, green: Double, blue: Double) {
        self.init(red: red / 255, green: green / 255, blue: blue / 255)
    }

    init?(hex: String) {
        var hexNormalized = hex.trimmingCharacters(in: .whitespacesAndNewlines)
        hexNormalized = hexNormalized.replacingOccurrences(of: "#", with: "")

        // Helpers
        var rgb: UInt64 = 0
        var r: CGFloat = 0.0
        var g: CGFloat = 0.0
        var b: CGFloat = 0.0
        var a: CGFloat = 1.0
        let length = hexNormalized.count

        // Create Scanner
        Scanner(string: hexNormalized).scanHexInt64(&rgb)

        if length == 6 {
            r = CGFloat((rgb & 0xFF0000) >> 16) / 255.0
            g = CGFloat((rgb & 0x00FF00) >> 8) / 255.0
            b = CGFloat(rgb & 0x0000FF) / 255.0

        } else if length == 8 {
            r = CGFloat((rgb & 0xFF000000) >> 24) / 255.0
            g = CGFloat((rgb & 0x00FF0000) >> 16) / 255.0
            b = CGFloat((rgb & 0x0000FF00) >> 8) / 255.0
            a = CGFloat(rgb & 0x000000FF) / 255.0

        } else {
            return nil
        }

        let uiColor = UIColor(red: r, green: g, blue: b, alpha: a)
        self.init(uiColor)
    }

    var toHex: String? {
        // Extract Components
        guard let components = cgColor?.components, components.count >= 3 else {
            return nil
        }
        
        // Helpers
        let r = Float(components[0])
        let g = Float(components[1])
        let b = Float(components[2])
        var a = Float(1.0)
        
        if components.count >= 4 {
            a = Float(components[3])
        }
        
        // Create Hex String
        let hex = String(format: "%02lX%02lX%02lX%02lX", lroundf(r * 255), lroundf(g * 255), lroundf(b * 255), lroundf(a * 255))
        
        return hex
    }
}
