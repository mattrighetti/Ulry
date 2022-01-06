//
//  MainFolder.swift
//  Urly
//
//  Created by Mattia Righetti on 12/25/21.
//

import Foundation
import SwiftUI

struct MainFolder: Hashable {
    static func == (lhs: MainFolder, rhs: MainFolder) -> Bool {
        lhs.name == rhs.name &&
        lhs.iconName == rhs.iconName &&
        lhs.color == rhs.color
    }
    
    let name: String
    let iconName: String
    let color: Color
    let filter: LinkFilter
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(name.hashValue)
        hasher.combine(iconName.hashValue)
        hasher.combine(color.hashValue)
    }
}
