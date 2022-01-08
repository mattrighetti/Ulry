//
//  Group+CoreDataProperties.swift
//  Urly
//
//  Created by Mattia Righetti on 1/8/22.
//

import CoreData

extension Group {
    @NSManaged public var id: UUID
    @NSManaged public var colorHex: String
    @NSManaged public var iconName: String
    @NSManaged public var name: String
    @NSManaged public var links: Set<Link>?
    
    public class func fetchRequest() -> NSFetchRequest<Group> {
        NSFetchRequest<Group>(entityName: "Group")
    }
    
    public class func fetchRequest(withUUID id: UUID) -> NSFetchRequest<Group> {
        let fetchGroup: NSFetchRequest<Group> = self.fetchRequest()
        fetchGroup.predicate = NSPredicate(format: "%K == %@", "id", id as CVarArg)
        return fetchGroup
    }
}
