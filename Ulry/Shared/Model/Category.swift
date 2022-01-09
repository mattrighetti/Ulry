//
//  Category.swift
//  Ulry
//
//  Created by Mattia Righetti on 1/9/22.
//

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
                LinkStorage.shared.getLinksCount(by: self)
            )
        case .unread:
            return (
                "Unread",
                UIColor.systemGray,
                "archivebox",
                LinkStorage.shared.getLinksCount(by: self)
            )
        case .starred:
            return (
                "Starred",
                UIColor.systemYellow,
                "star",
                LinkStorage.shared.getLinksCount(by: self)
            )
        case .group(let group):
            return (
                group.name,
                UIColor(hex: group.colorHex)!,
                group.iconName,
                LinkStorage.shared.getLinksCount(by: self)
            )
        case .tag(let tag):
            return (
                tag.name,
                UIColor(hex: tag.colorHex)!,
                nil,
                LinkStorage.shared.getLinksCount(by: self)
            )
        }
    }
    
    public func hash(into hasher: inout Hasher) {
        hasher.combine(self.rawValue.0)
        hasher.combine(self.rawValue.1)
        hasher.combine(self.rawValue.2)
        hasher.combine(self.rawValue.3)
    }
    
    public static func ==(lhs: Self, rhs: Self) -> Bool {
        lhs.rawValue.0 == rhs.rawValue.0 &&
        lhs.rawValue.1 == rhs.rawValue.1 &&
        lhs.rawValue.2 == rhs.rawValue.2 &&
        lhs.rawValue.3 == rhs.rawValue.3
    }
}
