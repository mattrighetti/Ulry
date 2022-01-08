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
    convenience init() {
        self.init(context: PersistenceController.shared.container.viewContext)
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
