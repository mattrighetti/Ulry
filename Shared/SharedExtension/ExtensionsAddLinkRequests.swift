//
//  ExtensionsContainer.swift
//  Ulry
//
//  Created by Matt on 27/11/2022.
//  Copyright © 2022 Mattia Righetti. All rights reserved.
//

import Foundation

struct ExtensionsAddLinkRequests: Codable, Equatable {
    let id: UUID
    let url: String
    let note: String?
    let date: Int
    let tagIds: [String]?
    let groupId: String?

    init(url: String, note: String?, tagIds: [String]? = nil, groupId: String? = nil) {
        self.id = UUID()
        self.url = url
        self.note = note
        self.tagIds = tagIds
        self.groupId = groupId
        self.date = Int(Date().timeIntervalSince1970)
    }

    private enum CodingKeys: String, CodingKey {
        case id, url, note, date, tagIds, groupId
    }

    init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        id = try values.decodeIfPresent(UUID.self, forKey: .id) ?? UUID()
        url = try values.decode(String.self, forKey: .url)
        note = try values.decodeIfPresent(String.self, forKey: .note)
        date = try values.decode(Int.self, forKey: .date)
        tagIds = try values.decodeIfPresent([String].self, forKey: .tagIds)
        groupId = try values.decodeIfPresent(String.self, forKey: .groupId)
    }

}
