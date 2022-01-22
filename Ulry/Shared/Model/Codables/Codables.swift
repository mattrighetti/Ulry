//
//  LinkCodable.swift
//  Ulry
//
//  Created by Mattia Righetti on 1/22/22.
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

struct GroupCodable: Codable {
    var id: UUID
    var colorHex: String
    var iconName: String
    var name: String
    var links: [UUID]?
    
    init(from group: Group) {
        self.id = group.id
        self.colorHex = group.colorHex
        self.iconName = group.iconName
        self.name = group.name
        
        if let links = group.links {
            self.links = links.map(\.id)
        }
    }
}

struct TagCodable: Codable {
    var id: UUID
    var colorHex: String
    var name: String
    var links: [UUID]?
    
    init(from tag: Tag) {
        self.id = tag.id
        self.colorHex = tag.colorHex
        self.name = tag.name
        
        if let links = tag.links {
            self.links = links.map(\.id)
        }
    }
}
