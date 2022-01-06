//
//  Tag.swift
//  Urly
//
//  Created by Mattia Righetti on 12/25/21.
//

import Foundation
import CoreData
import SwiftUI

public class Tag: NSManagedObject, Representable {
    @NSManaged public var id: UUID
    @NSManaged public var colorHex: String
    @NSManaged public var description_: String
    @NSManaged public var name: String
    @NSManaged public var links: Set<Link>?
}

extension Tag {
    public class func fetchRequest() -> NSFetchRequest<Tag> {
        NSFetchRequest<Tag>(entityName: "Tag")
    }
    
    public class func fetchRequest(withUUID id: UUID) -> NSFetchRequest<Tag> {
        let fetchTag: NSFetchRequest<Tag> = self.fetchRequest()
        fetchTag.predicate = NSPredicate(format: "%K == %@", "id", id as CVarArg)
        return fetchTag
    }
}

extension Tag {
    enum Request: RawRepresentable {
        case all
        case withUuid(uuid: UUID)
        
        typealias RawValue = NSFetchRequest<Tag>
        
        init?(rawValue: NSFetchRequest<Tag>) {
            return nil
        }
        
        var rawValue: NSFetchRequest<Tag> {
            switch self {
            case .all:
                let request: NSFetchRequest<Tag> = Tag.fetchRequest()
                request.sortDescriptors = [NSSortDescriptor(key: "name", ascending: true)]
                return request
            case .withUuid(uuid: let uuid):
                let request: NSFetchRequest<Tag> = Tag.fetchRequest(withUUID: uuid)
                request.sortDescriptors = []
                return request
            }
        }
    }
}
