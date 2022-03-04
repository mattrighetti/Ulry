//
//  Tag.swift
//  Urly
//
//  Created by Mattia Righetti on 12/25/21.
//

import Foundation
import FMDB

public class Tag: Hashable, Representable {
    public var id: UUID
    public var colorHex: String
    public var description_: String
    public var name: String
    public var links: Set<Link>? = nil
    
    init(id: UUID = UUID(), colorHex: String, description: String, name: String) {
        self.id = id
        self.colorHex = colorHex
        self.description_ = description
        self.name = name
        self.links = nil
    }
    
    init?(from res: FMResultSet) {
        self.id = UUID(uuidString: res.string(forColumn: "id")!)!
        self.colorHex = res.string(forColumn: "color")!
        self.description_ = res.string(forColumn: "description")!
        self.name = res.string(forColumn: "name")!
    }
    
    public static func == (lhs: Tag, rhs: Tag) -> Bool {
        lhs.id == rhs.id
    }
    
    public func hash(into hasher: inout Hasher) {
        hasher.combine(id)
        hasher.combine(colorHex)
        hasher.combine(description_)
        hasher.combine(name)
        hasher.combine(links)
    }
}
