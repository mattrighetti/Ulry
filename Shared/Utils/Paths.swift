//
//  Paths.swift
//  Ulry
//
//  Created by Mattia Righetti on 04/12/2022.
//  Copyright © 2022 Mattia Righetti. All rights reserved.
//

import Foundation

struct Paths {
    #if os(iOS)
    public static let dataFolder: URL = try! FileManager.default.url(for: .applicationSupportDirectory, in: .userDomainMask, appropriateFor: nil, create: true)
    #endif
}
