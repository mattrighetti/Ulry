//
//  Category.swift
//  Ulry
//
//  Created by Mattia Righetti on 1/9/22.
//

import UIKit

struct CategoryCellContent {
    var title: String
    var backgroundColor: UIColor
    var icon: String?
    var linksCount: Int
    
    init(title: String, backgroundColor: UIColor, icon: String?, linksCount: Int) {
        self.title = title
        self.backgroundColor = backgroundColor
        self.icon = icon
        self.linksCount = linksCount
    }
}

public enum Category: Hashable {
    case all
    case unread
    case starred
    case group(Group)
    case tag(Tag)
    
    public init?(rawValue: (String, UIColor, String?, Int)) {
        return nil
    }
    
    var cellContent: CategoryCellContent {
        switch self {
        case .all:
            return CategoryCellContent(title: "All", backgroundColor: .orange, icon: "list.bullet", linksCount: Database.shared.countLinks())
        case .unread:
            return CategoryCellContent(title: "Unread", backgroundColor: .systemGray, icon: "archivebox", linksCount: Database.shared.countUnreadLinks())
        case .starred:
            return CategoryCellContent(title: "Starred", backgroundColor: .systemYellow, icon: "star", linksCount: Database.shared.countStarredLinks())
        case .group(let group):
            return CategoryCellContent(title: group.name, backgroundColor: UIColor(hex: group.colorHex)!, icon: group.iconName, linksCount: Database.shared.countLinksIn(group))
        case .tag(let tag):
            return CategoryCellContent(title: tag.name, backgroundColor: UIColor(hex: tag.colorHex)!, icon: nil, linksCount: Database.shared.countLinksIn(tag))
        }
    }
}
