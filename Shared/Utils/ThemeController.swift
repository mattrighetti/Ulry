//
//  ThemeController.swift
//  Ulry
//
//  Created by Mattia Righetti on 1/21/22.
//  Copyright © 2022 Mattia Righetti. All rights reserved.
//

import UIKit

enum Theme: String {
    case light
    case dark
    case system
    
    var uiInterfaceStyle: UIUserInterfaceStyle {
        switch self {
        case .light:
            return .light
        case .dark:
            return .dark
        case .system:
            return .unspecified
        }
    }
}

class ThemeController: NSObject {
    private(set) lazy var currentTheme = loadTheme()
    private let defaults: UserDefaults
    private let defaultsKey = "theme"
    var handler: ((UIUserInterfaceStyle) -> Void)?

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
        super.init()
        self.defaults.addObserver(self, forKeyPath: DefaultsKey.theme.key, options: [.old, .new], context: nil)
    }

    func changeTheme(to theme: Theme) {
        currentTheme = theme
        defaults.setValue(theme.rawValue, forKey: defaultsKey)
    }

    private func loadTheme() -> Theme {
        let rawValue = defaults.string(forKey: defaultsKey)
        return rawValue.flatMap(Theme.init) ?? .light
    }
    
    override func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey: Any]?, context: UnsafeMutableRawPointer?) {
        guard
            handler != nil,
            let change = change,
            object != nil,
            keyPath == DefaultsKey.theme.key,
            let themeValue = change[.newKey] as? String,
            let theme = Theme(rawValue: themeValue)?.uiInterfaceStyle
        else { return }
        
        handler!(theme)
    }
    
    deinit {
        UserDefaults.standard.removeObserver(self, forKeyPath: DefaultsKey.theme.key, context: nil)
    }
}
