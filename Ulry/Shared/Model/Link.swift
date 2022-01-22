//
//  Link.swift
//  Urly
//
//  Created by Mattia Righetti on 12/25/21.
//

import os
import SwiftUI
import CoreData

public class Link: NSManagedObject {
    var hostname: String {
        guard
            let url = URL(string: self.url),
            var hostname = url.host
        else { return "invalid URL" }
        
        if hostname.starts(with: "www.") {
            hostname = hostname.replacingOccurrences(of: "www.", with: "")
        }
        
        return hostname
    }
    
    var color: Color {
        guard let color = Color(hex: self.colorHex) else { return Color(hex: "#333333")! }
        return color
    }
    
    var dateString: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "d MMM yy"
        let date = Date(timeIntervalSince1970: Double(self.createdAt))
        return formatter.string(from: date)
    }
    
    var needsUpdate: Bool = false
    
    convenience init() {
        self.init(context: CoreDataStack.shared.managedContext)
    }
}

extension Link {
    enum Request {
        case all
        case starred
        case unread
        case withUuid(uuid: UUID)
        case group(Group)
        case tag(Tag)
        
        init(from category: Category) {
            switch category {
            case .all:
                self = .all
            case .unread:
                self = .unread
            case .starred:
                self = .starred
            case .group(let group):
                self = .group(group)
            case .tag(let tag):
                self = .tag(tag)
            }
        }
        
        var fetchRequest: NSFetchRequest<Link> {
            let sort = [NSSortDescriptor(key: "createdAt", ascending: false)]
            let request: NSFetchRequest<Link>
            
            switch self {
            case .all:
                request = Link.fetchRequest()
            case .starred:
                request = Link.fetchRequest(starred: true)
            case .unread:
                request = Link.fetchRequest(unread: true)
            case .withUuid(uuid: let uuid):
                request = Link.fetchRequest(withUUID: uuid)
            case .group(let group):
                request = Link.fetchRequest(withGroup: group)
            case .tag(let tag):
                request = Link.fetchRequest(withTag: tag)
            }
            
            request.sortDescriptors = sort
            return request
        }
    }
}
