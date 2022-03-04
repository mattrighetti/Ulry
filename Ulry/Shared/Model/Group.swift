//
//  Group.swift
//  Urly
//
//  Created by Mattia Righetti on 12/25/21.
//

import Foundation
import FMDB

public class Group: Hashable, Representable {
    public var id: UUID
    public var colorHex: String
    public var iconName: String
    public var name: String
    public var links: Set<Link>?
    
    init(id: UUID = UUID(), colorHex: String, iconName: String, name: String, links: Set<Link>?) {
        self.id = id
        self.colorHex = colorHex
        self.iconName = iconName
        self.name = name
        self.links = links
    }
    
    init?(from res: FMResultSet) {
        self.id = UUID(uuidString: res.string(forColumn: "id")!)!
        self.colorHex = res.string(forColumn: "color")!
        self.iconName = res.string(forColumn: "icon")!
        self.name = res.string(forColumn: "name")!
    }
    
    public static func == (lhs: Group, rhs: Group) -> Bool {
        lhs.id == rhs.id
    }
    
    public func hash(into hasher: inout Hasher) {
        hasher.combine(id)
        hasher.combine(colorHex)
        hasher.combine(iconName)
        hasher.combine(name)
        hasher.combine(links)
    }
}
