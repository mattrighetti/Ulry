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
        self.init(context: CoreDataStack.shared.managedContext)
    }
}

extension Tag {
    enum Request {
        case all
        case withUuid(uuid: UUID)
        
        var fetchRequest: NSFetchRequest<Tag> {
            let request: NSFetchRequest<Tag>
            let sort = [NSSortDescriptor(key: "name", ascending: true)]
            
            switch self {
            case .all:
                request = Tag.fetchRequest()
            case .withUuid(uuid: let uuid):
                request = Tag.fetchRequest(withUUID: uuid)
            }
            
            request.sortDescriptors = sort
            return request
        }
    }
}
