//
//  Category.swift
//  Ulry
//
//  Created by Mattia Righetti on 1/9/22.
//

import CoreData
import UIKit

public enum Category: Hashable, RawRepresentable {
    case all
    case unread
    case starred
    case group(Group)
    case tag(Tag)
    
    public init?(rawValue: (String, UIColor, String?, Int)) {
        return nil
    }
    
    public typealias RawValue = (String, UIColor, String?, Int)
    public var rawValue: RawValue {
        switch self {
        case .all:
            return (
                "All",
                UIColor.orange,
                "list.bullet",
                try! CoreDataStack.shared.managedContext.count(for: Link.Request.all.rawValue)
            )
        case .unread:
            return (
                "Unread",
                UIColor.systemGray,
                "archivebox",
                try! CoreDataStack.shared.managedContext.count(for: Link.Request.unread.rawValue)
            )
        case .starred:
            return (
                "Starred",
                UIColor.systemYellow,
                "star",
                try! CoreDataStack.shared.managedContext.count(for: Link.Request.starred.rawValue)
            )
        case .group(let group):
            return (
                group.name,
                UIColor(hex: group.colorHex)!,
                group.iconName,
                try! CoreDataStack.shared.managedContext.count(for: Link.Request.folder(group).rawValue)
            )
        case .tag(let tag):
            return (
                tag.name,
                UIColor(hex: tag.colorHex)!,
                nil,
                try! CoreDataStack.shared.managedContext.count(for: Link.Request.tag(tag).rawValue)
            )
        }
    }
}
