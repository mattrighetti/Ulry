//
//  Tag.swift
//  Urly
//
//  Created by Mattia Righetti on 12/25/21.
//  Copyright © 2021 Mattia Righetti. All rights reserved.
//

import Foundation
import FMDB

public final class Tag: Hashable, Equatable {
    public var id: UUID
    public var name: String
    public var colorHex: String
    public var links: Set<Link>? = nil
    
    public init(id: UUID = UUID(), colorHex: String, name: String) {
        self.id = id
        self.colorHex = colorHex
        self.name = name
    }
    
    public init?(from res: FMResultSet) {
        self.id = UUID(uuidString: res.string(forColumn: "id")!)!
        self.colorHex = res.string(forColumn: "color")!
        self.name = res.string(forColumn: "name")!
    }
    
    public static func == (lhs: Tag, rhs: Tag) -> Bool {
        lhs.id == rhs.id && lhs === rhs
    }

    public static func ===(lhs: Tag, rhs: Tag) -> Bool {
        lhs.name == rhs.name &&
        lhs.colorHex == rhs.colorHex
    }
    
    public func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
}

extension Tag: Codable {}
