//
//  AppIcon.swift
//  Ulry
//
//  Created by Mattia Righetti on 1/27/22.
//

import UIKit

enum AppIcon: String, CaseIterable, Hashable {
    case `default` = "AppIcon"
    case yellow = "yellow"
    
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
            return "Default App Icon"
        case .yellow:
            return "Yellow App Icon"
        }
    }
    
    var subtitle: String {
        switch self {
        case .default:
            return "This is the original one!"
        case .yellow:
            return "Perfect if you're more on the warmer side of colors"
        }
    }
}
