//
//  Link.swift
//  Urly
//
//  Created by Mattia Righetti on 12/25/21.
//

import SwiftUI
import CoreData

public class Link: NSManagedObject {
    @NSManaged public var id: UUID?
    @NSManaged public var createdAt: Int32
    @NSManaged public var updatedAt: Int32
    @NSManaged public var note: String?
    @NSManaged public var starred: Bool
    @NSManaged public var unread: Bool
    @NSManaged public var url: String?
    @NSManaged public var ogTitle: String?
    @NSManaged public var ogDescription: String?
    @NSManaged public var ogImageUrl: String?
    @NSManaged public var group: Group?
    @NSManaged public var tags: [Tag]?
}

extension Link {
    public class func fetchRequest() -> NSFetchRequest<Link> {
        NSFetchRequest<Link>(entityName: "Link")
    }
    
    public class func fetchRequest(withUUID id: UUID) -> NSFetchRequest<Link> {
        let fetchLink: NSFetchRequest<Link> = self.fetchRequest()
        fetchLink.predicate = NSPredicate(format: "%K == %@", "id", id as CVarArg)
        return fetchLink
    }
    
    public class func fetchRequest(withTag tag: Tag) -> NSFetchRequest<Link> {
        let fetchLink: NSFetchRequest<Link> = self.fetchRequest()
        fetchLink.predicate = NSPredicate(format: "%@ IN tags", tag)
        return fetchLink
    }

    public class func fetchRequest(withGroup group: Group) -> NSFetchRequest<Link> {
        let fetchLink = NSFetchRequest<Link>(entityName: "Link")
        fetchLink.predicate = NSPredicate(format: "group == %@", group)
        return fetchLink
    }

    public class func fetchRequest(unread: Bool) -> NSFetchRequest<Link> {
        let fetchLink: NSFetchRequest<Link> = self.fetchRequest()
        fetchLink.predicate = NSPredicate(format: "unread == %@", NSNumber(booleanLiteral: unread))
        return fetchLink
    }

    public class func fetchRequest(starred: Bool) -> NSFetchRequest<Link> {
        let fetchLink: NSFetchRequest<Link> = self.fetchRequest()
        fetchLink.predicate = NSPredicate(format: "%K == %@", "starred", NSNumber(booleanLiteral: starred))
        return fetchLink
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
