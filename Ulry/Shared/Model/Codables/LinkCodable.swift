//
//  LinkCodable.swift
//  Ulry
//
//  Created by Mattia Righetti on 1/31/22.
//

import Foundation

struct LinkCodable: Codable {
    var id: UUID
    var createdAt: Int32
    var updatedAt: Int32
    var note: String?
    var starred: Bool
    var unread: Bool
    var url: String
    var colorHex: String
    var ogTitle: String?
    var ogDescription: String?
    var ogImageUrl: String?
    var group: GroupCodable?
    var tags: [TagCodable]?
    
    init(from link: Link) {
        self.id = link.id
        self.createdAt = link.createdAt
        self.updatedAt = link.updatedAt
        self.note = link.note
        self.starred = link.starred
        self.unread = link.unread
        self.url = link.url
        self.colorHex = link.colorHex
        self.ogTitle = link.ogTitle
        self.ogDescription = link.ogDescription
        self.ogImageUrl = link.ogImageUrl
        
        if let group = link.group {
            self.group = GroupCodable(from: group)
        }
        
        if let tags = link.tags {
            self.tags = tags.map { TagCodable(from: $0) }
        }
    }
}
