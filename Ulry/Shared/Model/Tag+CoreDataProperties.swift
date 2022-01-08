//
//  Tag+CoreDataProperties.swift
//  Urly
//
//  Created by Mattia Righetti on 1/8/22.
//

import CoreData

extension Tag {
    @NSManaged public var id: UUID
    @NSManaged public var colorHex: String
    @NSManaged public var description_: String
    @NSManaged public var name: String
    @NSManaged public var links: Set<Link>?
    
    public class func fetchRequest() -> NSFetchRequest<Tag> {
        NSFetchRequest<Tag>(entityName: "Tag")
    }
    
    public class func fetchRequest(withUUID id: UUID) -> NSFetchRequest<Tag> {
        let fetchTag: NSFetchRequest<Tag> = self.fetchRequest()
        fetchTag.predicate = NSPredicate(format: "%K == %@", "id", id as CVarArg)
        return fetchTag
    }
}
