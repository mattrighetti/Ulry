//
//  AppIcon.swift
//  Ulry
//
//  Created by Mattia Righetti on 1/27/22.
//  Copyright © 2022 Mattia Righetti. All rights reserved.
//

import UIKit

enum AppIcon: String, CaseIterable, Hashable {
    case `default` = "AppIcon"
    case dark_red = "dark_red"
    case light_black = "light_black"
    case light_blue = "light_blue"
    case light_orange = "light_orange"
    
    static var currentAppIcon: AppIcon {
        guard let name = UIApplication.shared.alternateIconName else { return .default }
        
        guard let appIcon = AppIcon(rawValue: name) else {
            fatalError("Provided unknown app icon value")
        }
        
        return appIcon
    }
    
    var thumbnail: UIImage {
        if self == .default {
            return UIImage(named: "thumb-default")!
        } else {
            return UIImage(named: "thumb-" + self.rawValue)!
        }
    }
    
    var title: String {
        switch self {
        case .default:
            return "Default"
        case .light_black:
            return "Light Black"
        case .light_blue:
            return "Light Blue"
        case .dark_red:
            return "Dark Red"
        case .light_orange:
            return "Light Orange"
        }
    }
    
    var subtitle: String? {
        switch self {
        case .default:
            return nil
        case .dark_red, .light_black, .light_blue, .light_orange:
            return nil
        }
    }
}
