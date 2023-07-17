//
//  +FileManager.swift
//  Ulry
//
//  Created by Matt on 03/12/2022.
//  Copyright © 2022 Mattia Righetti. All rights reserved.
//

import os
import Foundation

enum FileManagerError: Error {
    case fileIsPresent
}

extension FileManager {
    func secureCopyItem(at srcURL: URL, to dstURL: URL) -> Bool {
        do {
            if FileManager.default.fileExists(atPath: dstURL.path) {
                os_log(.error, "file is already present at \(dstURL.path), removing object so that new one can by copied over")
                throw FileManagerError.fileIsPresent
            }

            try FileManager.default.copyItem(at: srcURL, to: dstURL)
        } catch (let error) {
            os_log(.error, "Cannot copy item at \(srcURL) to \(dstURL): \(error)")
            return false
        }

        return true
    }
}
