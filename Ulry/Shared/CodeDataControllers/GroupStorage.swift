//
//  FolderStorage.swift
//  Urly
//
//  Created by Mattia Righetti on 1/2/22.
//

import os
import Combine
import CoreData

class GroupStorage: NSObject, ObservableObject {
    var groups = CurrentValueSubject<[Group], Never>([])
    static let shared = GroupStorage()
    private let tagFetchController: NSFetchedResultsController<Group>
    
    private override init() {
        tagFetchController = NSFetchedResultsController(
            fetchRequest: Group.Request.all.rawValue,
            managedObjectContext: PersistenceController.shared.container.viewContext,
            sectionNameKeyPath: nil,
            cacheName: nil
        )
        
        super.init()
        
        tagFetchController.delegate = self
        
        do {
            try tagFetchController.performFetch()
            groups.value = tagFetchController.fetchedObjects ?? []
        } catch {
            NSLog("Error: could not fetch tags")
        }
    }
    
    func add(name: String, color: String, icon: String) {
        let group = Group(context: PersistenceController.shared.container.viewContext)
        group.setValue(UUID(), forKey: "id")
        group.setValue(name, forKey: "name")
        group.setValue(color, forKey: "colorHex")
        group.setValue(icon, forKey: "iconName")

        saveContext()
    }
    
    func update(group: Group, name: String, color: String, icon: String) {
        group.setValue(name, forKey: "name")
        group.setValue(color, forKey: "colorHex")
        group.setValue(icon, forKey: "iconName")

        saveContext()
    }
    
    func delete(_ group: Group) {
        os_log(.debug, "deleting group: \(group)")
        PersistenceController.shared.container.viewContext.delete(group)
        saveContext()
    }
    
    private func saveContext() {
        do {
            try PersistenceController.shared.container.viewContext.save()
        } catch {
            os_log(.error, "\(error as NSObject)")
        }
    }
}

extension GroupStorage: NSFetchedResultsControllerDelegate {
    public func controllerDidChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {
        guard let groups = controller.fetchedObjects as? [Group] else { return }
        self.groups.value = groups
    }
}
