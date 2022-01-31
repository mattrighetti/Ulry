//
//  +URL.swift
//  Ulry
//
//  Created by Mattia Righetti on 1/12/22.
//

import Foundation

public extension URL {
    /// Returns a URL for the given app group and database pointing to the sqlite database.
    static func storeURL(for appGroup: String, databaseName: String) -> URL {
        guard let fileContainer = FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: appGroup) else {
            fatalError("Shared file container could not be created.")
        }

        return fileContainer.appendingPathComponent("\(databaseName).sqlite")
    }
    
    static let titleMeta = ["og:title", "title", "twitter:title"]
    static let descriptionMeta = ["og:description", "description", "twitter:description"]
    static let imageMeta = ["og:image", "og:image:src", "image", "image:src", "twitter:image:src"]
}
