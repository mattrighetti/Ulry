//
//  Link+CoreDataProperties.swift
//  Urly
//
//  Created by Mattia Righetti on 1/8/22.
//

import os
import CoreData
import UIKit

extension Link {
    @NSManaged public var id: UUID
    @NSManaged public var createdAt: Int32
    @NSManaged public var updatedAt: Int32
    @NSManaged public var note: String?
    @NSManaged public var starred: Bool
    @NSManaged public var unread: Bool
    @NSManaged public var url: String
    @NSManaged public var imageData: Data?
    @NSManaged public var colorHex: String
    @NSManaged public var ogTitle: String?
    @NSManaged public var ogDescription: String?
    @NSManaged public var ogImageUrl: String?
    @NSManaged public var group: Group?
    @NSManaged public var tags: Set<Tag>?
    
    public override func awakeFromInsert() {
        super.awakeFromInsert()
        setPrimitiveValue(UUID(), forKey: #keyPath(Link.id))
        setPrimitiveValue(UIColor.randomHexColorCode(), forKey: #keyPath(Link.colorHex))
        setPrimitiveValue(false, forKey: #keyPath(Link.starred))
        setPrimitiveValue(true, forKey: #keyPath(Link.unread))
        setPrimitiveValue(Int(Date.now.timeIntervalSince1970), forKey: #keyPath(Link.createdAt))
        setPrimitiveValue(Int(Date.now.timeIntervalSince1970), forKey: #keyPath(Link.updatedAt))
    }
    
    public override func willChangeValue(forKey key: String) {
        super.willChangeValue(forKey: key)
        if key == #keyPath(Link.url) {
            needsUpdate = true
        }
    }
    
    public override func willSave() {
        super.willSave()
        setPrimitiveValue(Int(Date.now.timeIntervalSince1970), forKey: #keyPath(Link.updatedAt))
    }
    
    // MARK: - Requests
    
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
