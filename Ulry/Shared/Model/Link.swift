//
//  Link.swift
//  Urly
//
//  Created by Mattia Righetti on 12/25/21.
//

import os
import SwiftUI
import FMDB

public class Link: Hashable {
    public var id: UUID
    public var createdAt: Int32
    public var updatedAt: Int32
    public var note: String?
    public var starred: Bool
    public var unread: Bool
    public var url: String
    public var imageData: Data?
    public var colorHex: String
    public var ogTitle: String?
    public var ogDescription: String?
    public var ogImageUrl: String?
    public var group: Group?
    public var tags: Set<Tag>?
    
    init(url: String, note: String? = nil) {
        self.id = UUID()
        self.createdAt = Int32(Date.now.timeIntervalSince1970)
        self.updatedAt = Int32(Date.now.timeIntervalSince1970)
        self.starred = false
        self.unread = true
        self.url = url
        self.colorHex = Color.randomHexColorCode()
        self.ogTitle = nil
        self.ogDescription = nil
        self.ogImageUrl = nil
        self.group = nil
        self.tags = nil
    }
    
    init?(from res: FMResultSet) {
        self.id = UUID(uuidString: res.string(forColumn: "id")!)!
        self.starred = res.bool(forColumn: "starred")
        self.unread = res.bool(forColumn: "unread")
        self.url = res.string(forColumn: "url")!
        self.note = res.string(forColumn: "note")
        self.imageData = res.string(forColumn: "image")?.data(using: .ascii)
        self.colorHex = res.string(forColumn: "color")!
        self.ogTitle = res.string(forColumn: "ogTitle")
        self.ogDescription = res.string(forColumn: "ogDescription")
        self.ogImageUrl = res.string(forColumn: "ogImage")
        self.createdAt = Int32(Date.now.timeIntervalSince1970)
        self.updatedAt = Int32(Date.now.timeIntervalSince1970)
        self.group = nil
        self.tags = nil
    }
    
    var hostname: String {
        guard
            let url = URL(string: self.url),
            var hostname = url.host
        else { return "invalid URL" }
        
        if hostname.starts(with: "www.") {
            hostname = hostname.replacingOccurrences(of: "www.", with: "")
        }
        
        return hostname
    }
    
    var color: Color {
        guard let color = Color(hex: self.colorHex) else { return Color(hex: "#333333")! }
        return color
    }
    
    var dateString: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "d MMM yy"
        let date = Date(timeIntervalSince1970: Double(self.createdAt))
        return formatter.string(from: date)
    }
    
    var needsUpdate: Bool = false
    
    lazy var imageBase64Representation: String? = {
        self.imageData?.base64EncodedString()
    }()
    
    public static func == (lhs: Link, rhs: Link) -> Bool {
        lhs.id == rhs.id
    }
    
    public func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
}
