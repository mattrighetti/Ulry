//
//  Link.swift
//  Urly
//
//  Created by Mattia Righetti on 12/25/21.
//  Copyright © 2021 Mattia Righetti. All rights reserved.
//

import os
import SwiftUI
import FMDB

public final class Link: Hashable, Equatable {
    public var id: UUID
    public var createdAt: Int32
    public var updatedAt: Int32
    public var note: String? {
        didSet {
            guard let noteClean = note?.trimmingCharacters(in: .whitespaces) else { return }
            if !noteClean.isEmpty {
                note = noteClean
            } else {
                note = nil
            }
        }
    }
    public var starred: Bool
    public var archived: Bool
    public var unread: Bool
    public var url: String
    public var colorHex: String
    public var ogTitle: String? {
        didSet {
            guard let ogTitleClean = ogTitle?.trimmingCharacters(in: .whitespaces) else { return }
            ogTitle = ogTitleClean.isEmpty ? nil : ogTitleClean
        }
    }
    public var ogDescription: String?
    public var ogImageUrl: String?
    public var group: Group? = nil
    public var tags: Set<Tag>? = nil

    public init(url: String, note: String? = nil) {
        self.id = UUID()
        self.createdAt = Int32(Date.now.timeIntervalSince1970)
        self.updatedAt = Int32(Date.now.timeIntervalSince1970)
        self.note = note
        self.starred = false
        self.archived = false
        self.unread = true
        self.url = url
        self.colorHex = Color.randomHexColorCode()
        self.ogTitle = nil
        self.ogDescription = nil
        self.ogImageUrl = nil
    }

    public init?(from res: FMResultSet) {
        self.id = UUID(uuidString: res.string(forColumn: "id")!)!
        self.starred = res.bool(forColumn: "starred")
        self.unread = res.bool(forColumn: "unread")
        self.archived = res.bool(forColumn: "archived")
        self.url = res.string(forColumn: "url")!
        self.note = res.string(forColumn: "note")
        self.colorHex = res.string(forColumn: "color")!
        self.ogTitle = res.string(forColumn: "ogTitle")
        self.ogDescription = res.string(forColumn: "ogDescription")
        self.ogImageUrl = res.string(forColumn: "ogImageUrl")
        self.createdAt = res.int(forColumn: "created_at")
        self.updatedAt = res.int(forColumn: "updated_at")
    }
    
    public var hostname: String {
        guard
            let url = URL(string: self.url),
            var hostname = url.host
        else { return "invalid URL" }
        
        if hostname.starts(with: "www.") {
            hostname = hostname.replacingOccurrences(of: "www.", with: "")
        }
        
        return hostname
    }
    
    public var color: Color {
        guard let color = Color(hex: self.colorHex) else { return Color(hex: "#333333")! }
        return color
    }
    
    public var dateString: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "d MMM yy"
        let date = Date(timeIntervalSince1970: Double(createdAt))
        return formatter.string(from: date)
    }

    var needsUpdate: Bool = false
    
    public static func ==(lhs: Link, rhs: Link) -> Bool {
        lhs.id == rhs.id && lhs === rhs
    }

    public static func ===(lhs: Link, rhs: Link) -> Bool {
        lhs.unread == rhs.unread &&
        lhs.starred == rhs.starred &&
        lhs.archived == rhs.archived &&
        lhs.note == rhs.note &&
        lhs.ogTitle == rhs.ogTitle &&
        lhs.ogDescription == rhs.ogDescription &&
        lhs.ogImageUrl == rhs.ogImageUrl &&
        lhs.colorHex == rhs.colorHex &&
        lhs.url == rhs.url &&
        lhs.group == rhs.group &&
        lhs.tags == rhs.tags
    }
    
    public func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
}

extension Link: Codable {}
