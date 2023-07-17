//
//  ExtensionsContainer.swift
//  Ulry
//
//  Created by Matt on 27/11/2022.
//  Copyright © 2022 Mattia Righetti. All rights reserved.
//

import Foundation

struct ExtensionsAddLinkRequests: Codable {
    let url: String
    let note: String?
    let date: Int

    init(url: String, note: String?) {
        self.url = url
        self.note = note
        self.date = Int(Date().timeIntervalSince1970)
    }
}
