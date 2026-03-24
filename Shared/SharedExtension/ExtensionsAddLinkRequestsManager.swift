//
//  LinkAddRequestFile.swift
//  Ulry
//
//  Created by Matt on 27/11/2022.
//  Copyright © 2022 Mattia Righetti. All rights reserved.
//

import Foundation

final class ExtensionsAddLinkRequestsManager: Logging {

    private static let suite = "group.com.mattrighetti.Ulry"
    private static let key = "pendingLinks"

    private var defaults: UserDefaults? {
        UserDefaults(suiteName: Self.suite)
    }

    var canSaveMoreLinks: Bool {
        pendingLinks.count < 15
    }

    var pendingLinks: [ExtensionsAddLinkRequests] {
        guard
            let data = defaults?.data(forKey: Self.key),
            let links = try? JSONDecoder().decode([ExtensionsAddLinkRequests].self, from: data)
        else { return [] }
        return links
    }

    /// Stores given `urlString` and `note` to UserDefaults
    func add(_ urlString: String, note: String?) {
        logger.info("saving \(urlString) with note \(note ?? "")")
        var links = pendingLinks
        links.append(ExtensionsAddLinkRequests(url: urlString, note: note))
        if let data = try? JSONEncoder().encode(links) {
            defaults?.set(data, forKey: Self.key)
        }
    }

    func clearAll() {
        defaults?.removeObject(forKey: Self.key)
    }
}
