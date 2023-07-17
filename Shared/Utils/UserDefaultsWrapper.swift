//
//  Defaults.swift
//  Ulry
//
//  Created by Mattia Righetti on 1/21/22.
//  Copyright © 2022 Mattia Righetti. All rights reserved.
//

import Foundation

struct UserDefaultsWrapper {
    let userDefaults: UserDefaults = .standard

    func registerDefaults() {
        let dict = DefaultsKey.allCases.reduce(into: [String:Any]()) {
            $0[$1.key] = $1.initRegisterValue
        }
        UserDefaults.standard.register(defaults: dict)
    }

    func set(_ value: Any?, forKey key: DefaultsKey) {
        userDefaults.set(value, forKey: key.key)
    }

    func get<T>(key: DefaultsKey) -> T {
        userDefaults.object(forKey: key.key) as! T
    }

    func optionalGet<T>(key: DefaultsKey) -> T? {
        userDefaults.object(forKey: key.key) as? T
    }

    func removeObject(forKey key: DefaultsKey) {
        userDefaults.removeObject(forKey: key.key)
    }

    func getDecoded<T: Decodable>(key: DefaultsKey) -> T? {
        userDefaults.retrieve(object: T.self, fromKey: key.key)
    }

    func setEncoded(_ value: Codable, forKey key: DefaultsKey) {
        userDefaults.save(customObject: value, inKey: key.key)
    }
}

enum DefaultsKey: CaseIterable {
    case isFirstLaunch
    case openInApp
    case readMode
    case markReadOnOpen
    case theme
    case isPremium
    case orderBy
    case linkCellAppearence
    case collapsedSections

    case lastShownWhatsNew

    case redirectTwitter
    case redirectYoutube
    case redirectMedium
    case redirectReddit
    case redirectReuters

    case reviewWorthyActionCount
    case lastReviewRequestAppVersion

    var key: String {
        switch self {
        case .isFirstLaunch:
            return "is-first-launch"
        case .openInApp:
            return "open-externally"
        case .readMode:
            return "read-mode"
        case .markReadOnOpen:
            return "mark-read-on-open"
        case .theme:
            return "theme"
        case .isPremium:
            return "is-premium"
        case .orderBy:
            return "order-by"
        case .linkCellAppearence:
            return "link-cell-appearence"
        case .collapsedSections:
            return "collapsed-sections"
        case .lastShownWhatsNew:
            return "last-shown-whats-new"
        case .redirectTwitter:
            return "redirect.twitter"
        case .redirectYoutube:
            return "redirect.youtube"
        case .redirectMedium:
            return "redirect.medium"
        case .redirectReddit:
            return "redirect.reddit"
        case .redirectReuters:
            return "redirect.reuters"
        case .reviewWorthyActionCount:
            return "app-review-worthy-actionCount"
        case .lastReviewRequestAppVersion:
            return "app-review-last-review-request-app-version"
        }
    }

    var initRegisterValue: Any? {
        switch self {
        case .isFirstLaunch:
            return true
        case .openInApp:
            return false
        case .readMode:
            return false
        case .markReadOnOpen:
            return false
        case .theme:
            return Theme.system.rawValue
        case .isPremium:
            return false
        case .orderBy:
            return nil
        case .linkCellAppearence:
            return LinkCollectionViewCell.Appearence.complete.rawValue
        case .collapsedSections:
            return Array(repeatElement(false, count: 3))
        case .redirectTwitter, .redirectYoutube,
             .redirectMedium, .redirectReddit,
             .redirectReuters:
            return false
        case .lastShownWhatsNew:
            return nil
        case .reviewWorthyActionCount:
            return 0
        case .lastReviewRequestAppVersion:
            return nil
        }
    }
}
