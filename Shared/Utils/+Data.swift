//
//  +Data.swift
//  Ulry
//
//  Created by Mattia Righetti on 08/04/23.
//  Copyright © 2023 Mattia Righetti. All rights reserved.
//

import Foundation

extension Data {
    /// String value representing the data size in bytes
    var sizeString: String {
        let bcf = ByteCountFormatter()
        bcf.allowedUnits = [.useAll]
        bcf.countStyle = .file
        return bcf.string(fromByteCount: Int64(self.count))
    }
}
