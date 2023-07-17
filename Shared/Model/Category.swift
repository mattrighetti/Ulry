//
//  Category.swift
//  Ulry
//
//  Created by Mattia Righetti on 1/9/22.
//  Copyright © 2022 Mattia Righetti. All rights reserved.
//

import Links
import UIKit

struct CategoryCellContent {
    var title: String
    var backgroundColor: UIColor
    var icon: String?
    
    init(title: String, backgroundColor: UIColor, icon: String? = nil) {
        self.title = title
        self.backgroundColor = backgroundColor
        self.icon = icon
    }
}

public enum Category: Hashable {
    case all
    case unread
    case starred
    case archived
    case group(Group)
    case tag(Tag)
    
    public init?(rawValue: (String, UIColor, String?)) {
        return nil
    }
    
    var cellContent: CategoryCellContent {
        switch self {
        case .all:
            return CategoryCellContent(title: "All", backgroundColor: .init(hex: "D46C4E")!, icon: "list.bullet")
        case .unread:
            return CategoryCellContent(title: "Unread", backgroundColor: .init(hex: "CCABD8")!, icon: "archivebox")
        case .starred:
            return CategoryCellContent(title: "Starred", backgroundColor: .init(hex: "FFCE35")!, icon: "star")
        case .archived:
            return CategoryCellContent(title: "Archived", backgroundColor: .lightGray, icon: "tray")
        case .group(let group):
            return CategoryCellContent(title: group.name, backgroundColor: UIColor(hex: group.colorHex)!, icon: group.iconName)
        case .tag(let tag):
            return CategoryCellContent(title: tag.name, backgroundColor: UIColor(hex: tag.colorHex)!)
        }
    }
}
