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
        self.init(context: PersistenceController.shared.container.viewContext)
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
                request.sortDescriptors = [NSSortDescriptor(key: "name", ascending: true)]
                return request
            case .withUuid(uuid: let uuid):
                let request: NSFetchRequest<Group> = Group.fetchRequest(withUUID: uuid)
                request.sortDescriptors = []
                return request
            }
        }
    }
}
