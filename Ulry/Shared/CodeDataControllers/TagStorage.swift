//
//  TagStorage.swift
//  Urly
//
//  Created by Mattia Righetti on 1/2/22.
//

import os
import Combine
import CoreData

class TagStorage: NSObject, ObservableObject {
    var tags = CurrentValueSubject<[Tag], Never>([])
    static let shared = TagStorage()
    private let tagFetchController: NSFetchedResultsController<Tag>
    
    private override init() {
        tagFetchController = NSFetchedResultsController(
            fetchRequest: Tag.Request.all.rawValue,
            managedObjectContext: PersistenceController.shared.container.viewContext,
            sectionNameKeyPath: nil,
            cacheName: nil
        )
        
        super.init()
        
        tagFetchController.delegate = self
        
        do {
            try tagFetchController.performFetch()
            tags.value = tagFetchController.fetchedObjects ?? []
        } catch {
            NSLog("Error: could not fetch tags")
        }
    }
    
    func add(name: String, description: String, color: String) {
        let tag = Tag(context: PersistenceController.shared.container.viewContext)
        tag.setValue(UUID(), forKey: "id")
        tag.setValue(name, forKey: "name")
        tag.setValue(description, forKey: "description_")
        tag.setValue(color, forKey: "colorHex")

        saveContext()
    }
    
    func update(tag: Tag, name: String, description: String, color: String) {
        tag.setValue(name, forKey: "name")
        tag.setValue(description, forKey: "description_")
        tag.setValue(color, forKey: "colorHex")

        saveContext()
    }
    
    func delete(tag: Tag) {
        PersistenceController.shared.container.viewContext.delete(tag)
        saveContext()
    }
    
    private func saveContext() {
        do {
            try PersistenceController.shared.container.viewContext.save()
        } catch {
            os_log(.error, "error while saving context: \(error as NSObject)")
        }
    }
}

extension TagStorage: NSFetchedResultsControllerDelegate {
    public func controllerDidChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {
        guard let tags = controller.fetchedObjects as? [Tag] else { return }
        self.tags.value = tags
    }
}