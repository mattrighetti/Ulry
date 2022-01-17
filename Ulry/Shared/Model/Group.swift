//
//  Group.swift
//  Urly
//
//  Created by Mattia Righetti on 12/25/21.
//

import SwiftUI
import CoreData

public class Group: NSManagedObject, Representable {
    convenience init() {
        self.init(context: CoreDataStack.shared.managedContext)
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
            let request: NSFetchRequest<Group>
            let sort = [NSSortDescriptor(key: "name", ascending: true)]
            
            switch self {
            case .all:
                request = Group.fetchRequest()
            case .withUuid(uuid: let uuid):
                request = Group.fetchRequest(withUUID: uuid)
            }
            
            request.sortDescriptors = sort
            return request
        }
    }
}
