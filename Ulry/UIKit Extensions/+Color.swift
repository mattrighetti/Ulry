//
//  +Color.swift
//  Urly
//
//  Created by Mattia Righetti on 12/25/21.
//

import SwiftUI

extension Color {
    // MARK: - Colors
    public static var flatBlack: Color {
        return Color(decimalRed: 28, green: 28, blue: 29)
    }
    
    public static var outlineRed: Color {
        return Color(decimalRed: 34, green: 0, blue: 3)
    }

    public static var darkRed: Color {
        return Color(decimalRed: 221, green: 31, blue: 59)
    }

    public static var lightRed: Color {
        return Color(decimalRed: 239, green: 54, blue: 128)
    }
    
    public static var flatRed: Color {
        return Color(decimalRed: 202, green: 86, blue: 86)
    }

    public static var flatLightRed: Color {
        return Color(decimalRed: 213, green: 101, blue: 70)
    }

    public static var flatOrange: Color {
        return Color(decimalRed: 182, green: 106, blue: 57)
    }

    public static var flatLightOrange: Color {
        return Color(decimalRed: 199, green: 148, blue: 64)
    }

    public static var flatGreen: Color {
        return Color(decimalRed: 103, green: 148, blue: 74)
    }
    
    public static var flatLightGreen: Color {
        return Color(decimalRed: 88, green: 152, blue: 130)
    }
    
    public static var flatAirForceBlue: Color {
        return Color(decimalRed: 95, green: 148, blue: 168)
    }
    
    public static var flatShakespeare: Color {
        return Color(decimalRed: 100, green: 137, blue: 185)
    }
    
    public static var flatBlue: Color {
        return Color(decimalRed: 123, green: 99, blue: 195)
    }

    public static var flatLightBlue: Color {
        return Color(decimalRed: 99, green: 114, blue: 186)
    }
    
    public static var flatDeepLilac: Color {
        return Color(decimalRed: 170, green: 104, blue: 184)
    }

    public static var flatStormGrey: Color {
        return Color(decimalRed: 107, green: 109, blue: 134)
    }

    public static var flatRaven: Color {
        return Color(decimalRed: 108, green: 118, blue: 129)
    }

    public static var flatBlueSmoke: Color {
        return Color(decimalRed: 117, green: 126, blue: 120)
    }

    public static var flatHurricane: Color {
        return Color(decimalRed: 128, green: 118, blue: 114)
    }
    
    // MARK: - ColorSet Utils
    
    public static var background: Color {
        return Color("background")
    }
    
    public static var cardBackground: Color {
        return Color("cardBackground")
    }
    
    public static var random: Color {
        let randomHex = self.randomHexColorCode()
        return Color(hex: randomHex)!
    }

    // MARK: - Gradients
    public static var gradientsPalette: [Color] = [
        .flatRed,
        .flatLightRed,
        .flatOrange,
        .flatLightOrange,
        .flatGreen,
        .flatLightGreen,
        .flatAirForceBlue,
        .flatShakespeare,
        .flatBlue,
        .flatLightBlue,
        .flatDeepLilac,
        .flatStormGrey,
        .flatRaven,
        .flatBlueSmoke,
        .flatHurricane
    ]
    
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
