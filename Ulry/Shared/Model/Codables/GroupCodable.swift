//
//  GroupCodable.swift
//  Ulry
//
//  Created by Mattia Righetti on 1/31/22.
//

import Foundation

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
