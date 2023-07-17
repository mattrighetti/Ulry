//
//  URLRedirector.swift
//  Ulry
//
//  Created by Mattia Righetti on 10/19/22.
//  Copyright © 2022 Mattia Righetti. All rights reserved.
//

import os
import Links
import Foundation
import SafariServices

enum FOSSRedirection: String {
    case twitter = "twitter"
    case youtube = "youtube"
    case medium = "medium"
    case reddit = "reddit"
    case reuters = "reuters"

    var title: String {
        switch self {
        case .twitter:
            return "Twitter"
        case .youtube:
            return "YouTube"
        case .medium:
            return "Medium"
        case .reddit:
            return "Reddit"
        case .reuters:
            return "Reuters"
        }
    }

    var isActive: Bool {
        switch self {
        case .twitter:
            return UserDefaultsWrapper().get(key: .redirectTwitter)
        case .youtube:
            return UserDefaultsWrapper().get(key: .redirectYoutube)
        case .medium:
            return UserDefaultsWrapper().get(key: .redirectMedium)
        case .reddit:
            return UserDefaultsWrapper().get(key: .redirectReddit)
        case .reuters:
            return UserDefaultsWrapper().get(key: .redirectReuters)
        }
    }

    func toggle() {
        switch self {
        case .twitter:
            UserDefaultsWrapper().set(!isActive, forKey: .redirectTwitter)
        case .youtube:
            UserDefaultsWrapper().set(!isActive, forKey: .redirectYoutube)
        case .medium:
            UserDefaultsWrapper().set(!isActive, forKey: .redirectMedium)
        case .reddit:
            UserDefaultsWrapper().set(!isActive, forKey: .redirectReddit)
        case .reuters:
            UserDefaultsWrapper().set(!isActive, forKey: .redirectReuters)
        }
    }
}

struct URLRedirector {
    private let farsideInstance = "farside.link";
    private var redirect: [FOSSRedirection:Bool] = [
        .medium: UserDefaultsWrapper().get(key: .redirectMedium),
        .reddit: UserDefaultsWrapper().get(key: .redirectReddit),
        .twitter: UserDefaultsWrapper().get(key: .redirectTwitter),
        .youtube: UserDefaultsWrapper().get(key: .redirectYoutube),
        .reuters: UserDefaultsWrapper().get(key: .redirectReuters)
    ]
}

extension URLRedirector {
    mutating func setCustomRedirect(_ vals: [FOSSRedirection:Bool]) {
        redirect = vals
    }

    func redirect(_ link: Link) -> URL? {
        if let url = URL(string: link.url) {
            return redirect(url)
        }
        return nil
    }

    func redirect(_ url: URL) -> URL {
        guard let hostname = url.host else { return url }

        switch hostname {
        case "twitter.com", "www.twitter.com", "mobile.twitter.com":
            return redirectTwitter(url)
        case "youtube.com", "www.youtube.com", "m.youtube.com", "www.youtube-nocookie.com":
            return redirectYoutube(url)
        case "reddit.com", "www.reddit.com", "old.reddit.com":
            return redirectReddit(url)
        default:
            if (hostname.contains("medium.com")) {
                return redirectMedium(url)
            }
        }
        os_log(.debug, "no redirection is available for: \(url.absoluteString)")
        return url
    }

    private func redirectTwitter(_ url: URL) -> URL {
        guard redirect[.twitter]! else { return url }
        guard let urlComponents = redirectUrlComponents(of: url, prepending: "nitter") else { return url }
        return urlComponents.url ?? url
    }

    private func redirectYoutube(_ url: URL, youtubeFrontend: String = "piped") -> URL {
        guard redirect[.youtube]! else { return url }
        guard let urlComponents = redirectUrlComponents(of: url, prepending: youtubeFrontend) else { return url }
        return urlComponents.url ?? url
    }

    private func redirectReddit(_ url: URL) -> URL {
        guard redirect[.reddit]! else { return url }
        guard let urlComponents = redirectUrlComponents(of: url, prepending: "libreddit") else { return url }
        return urlComponents.url ?? url
    }

    private func redirectMedium(_ url: URL) -> URL {
        guard redirect[.medium]! else { return url }
        guard let urlComponents = redirectUrlComponents(of: url, prepending: "scribe") else { return url }
        return urlComponents.url ?? url
    }

    private func redirectReuters(_ url: URL) -> URL {
        guard redirect[.medium]! else { return url }
        guard var urlComponents = URLComponents(url: url, resolvingAgainstBaseURL: false) else { return url }
        urlComponents.host = "neuters.de"
        return urlComponents.url ?? url
    }

    private func redirectUrlComponents(of url: URL, prepending path: String) -> URLComponents? {
        guard var urlComponents = URLComponents(url: url, resolvingAgainstBaseURL: false) else { return nil }
        let tmpPath = urlComponents.path
        urlComponents.host = farsideInstance
        if path.starts(with: "/") {
            urlComponents.path = path + tmpPath
        } else {
            urlComponents.path = "/" + path + tmpPath
        }
        return urlComponents
    }
}
