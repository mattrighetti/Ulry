//
//  Category.swift
//  Ulry
//
//  Created by Mattia Righetti on 1/9/22.
//

import CoreData
import UIKit

struct CategoryCellContent {
    var title: String
    var backgroundColor: UIColor
    var icon: String?
    var linksCount: Int
    
    init(title: String, backgroundColor: UIColor, icon: String?, linksCount: Link.Request) {
        self.title = title
        self.backgroundColor = backgroundColor
        self.icon = icon
        self.linksCount = try! CoreDataStack.shared.managedContext.count(for: linksCount.fetchRequest)
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
            return CategoryCellContent(title: "All", backgroundColor: .orange, icon: "list.bullet", linksCount: .all)
        case .unread:
            return CategoryCellContent(title: "Unread", backgroundColor: .systemGray, icon: "archivebox", linksCount: .unread)
        case .starred:
            return CategoryCellContent(title: "Starred", backgroundColor: .systemYellow, icon: "star", linksCount: .starred)
        case .group(let group):
            return CategoryCellContent(title: group.name, backgroundColor: UIColor(hex: group.colorHex)!, icon: group.iconName, linksCount: .group(group))
        case .tag(let tag):
            return CategoryCellContent(title: tag.name, backgroundColor: UIColor(hex: tag.colorHex)!, icon: nil, linksCount: .tag(tag))
        }
    }
}
