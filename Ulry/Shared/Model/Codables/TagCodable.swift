//
//  LinkCodable.swift
//  Ulry
//
//  Created by Mattia Righetti on 1/22/22.
//

import Foundation

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
