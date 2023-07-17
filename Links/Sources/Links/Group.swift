//
//  Group.swift
//  Urly
//
//  Created by Mattia Righetti on 12/25/21.
//  Copyright © 2021 Mattia Righetti. All rights reserved.
//

import Foundation
import FMDB

public final class Group: Hashable, Equatable {
    public var id: UUID
    public var name: String
    public var colorHex: String
    public var iconName: String
    public var links: Set<Link>?
    
    public init(id: UUID = UUID(), colorHex: String, iconName: String, name: String, links: Set<Link>? = nil) {
        self.id = id
        self.colorHex = colorHex
        self.iconName = iconName
        self.name = name
        self.links = links
    }
    
    public init?(from res: FMResultSet) {
        self.id = UUID(uuidString: res.string(forColumn: "id")!)!
        self.colorHex = res.string(forColumn: "color")!
        self.iconName = res.string(forColumn: "icon")!
        self.name = res.string(forColumn: "name")!
    }
    
    public static func == (lhs: Group, rhs: Group) -> Bool {
        lhs.id == rhs.id && lhs === rhs
    }

    public static func ===(lhs: Group, rhs: Group) -> Bool {
        lhs.name == rhs.name &&
        lhs.colorHex == rhs.colorHex &&
        lhs.iconName == rhs.iconName
    }
    
    public func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
}

extension Group: Codable {}
