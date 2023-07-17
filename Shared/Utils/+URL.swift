//
//  +URL.swift
//  Ulry
//
//  Created by Mattia Righetti on 1/12/22.
//  Copyright © 2022 Mattia Righetti. All rights reserved.
//

import Foundation

public extension URL {
    /// Returns a URL for the given app group and database pointing to the sqlite database.
    static func storeURL(for appGroup: String, folders: [String]? = nil, filename: String) -> URL {
        guard let fileContainer = FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: appGroup) else {
            fatalError("Shared file container could not be created.")
        }

        var path: URL = fileContainer
        if let folders = folders {
            for folder in folders {
                path = path.appendingPathExtension(folder)
            }
        }
        return path.appendingPathComponent(filename)
    }
}
