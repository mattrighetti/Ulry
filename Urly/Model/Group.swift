//
//  Group.swift
//  Urly
//
//  Created by Mattia Righetti on 12/25/21.
//

import SwiftUI
import CoreData

public struct GroupMock {
    public var id: UUID
    public var colorHex: String
    public var iconName: String
    public var name: String
}

public class Group: NSManagedObject, Representable {
    @NSManaged public var id: UUID
    @NSManaged public var colorHex: String
    @NSManaged public var iconName: String
    @NSManaged public var name: String
    @NSManaged public var links: [Link]?
}

extension Group {
    public class func fetchRequest() -> NSFetchRequest<Group> {
        NSFetchRequest<Group>(entityName: "Group")
    }
    
    public class func fetchRequest(withUUID id: UUID) -> NSFetchRequest<Group> {
        let fetchGroup: NSFetchRequest<Group> = self.fetchRequest()
        fetchGroup.predicate = NSPredicate(format: "%K == %@", "id", id as CVarArg)
        return fetchGroup
    }
}

extension Group {
    enum Request: RawRepresentable {
        case all
        case withUuid(uuid: UUID)
        
        typealias RawValue = NSFetchRequest<Group>
        
        init?(rawValue: NSFetchRequest<Group>) {
            return nil
        }
        
        var rawValue: NSFetchRequest<Group> {
            switch self {
            case .all:
                let request: NSFetchRequest<Group> = Group.fetchRequest()
                request.sortDescriptors = []
                return request
            case .withUuid(uuid: let uuid):
                let request: NSFetchRequest<Group> = Group.fetchRequest(withUUID: uuid)
                request.sortDescriptors = []
                return request
            }
        }
    }
}
