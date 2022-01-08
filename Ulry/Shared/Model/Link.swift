//
//  Link.swift
//  Urly
//
//  Created by Mattia Righetti on 12/25/21.
//

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
    
    convenience init() {
        self.init(context: PersistenceController.shared.container.viewContext)
    }
}

extension Link {
    enum Request: RawRepresentable {
        case all
        case starred
        case unread
        case withUuid(uuid: UUID)
        case folder(Group)
        case tag(Tag)
        
        typealias RawValue = NSFetchRequest<Link>
        
        init?(rawValue: NSFetchRequest<Link>) {
            return nil
        }
        
        var rawValue: NSFetchRequest<Link> {
            switch self {
            case .all:
                let request: NSFetchRequest<Link> = Link.fetchRequest()
                request.sortDescriptors = []
                return request
            case .starred:
                let request: NSFetchRequest<Link> = Link.fetchRequest(starred: true)
                request.sortDescriptors = []
                return request
            case .unread:
                let request: NSFetchRequest<Link> = Link.fetchRequest(unread: true)
                request.sortDescriptors = []
                return request
            case .withUuid(uuid: let uuid):
                let request: NSFetchRequest<Link> = Link.fetchRequest(withUUID: uuid)
                request.sortDescriptors = []
                return request
            case .folder(let group):
                let request: NSFetchRequest<Link> = Link.fetchRequest(withGroup: group)
                request.sortDescriptors = []
                return request
            case .tag(let tag):
                let request: NSFetchRequest<Link> = Link.fetchRequest(withTag: tag)
                request.sortDescriptors = []
                return request
            }
        }
    }
}
