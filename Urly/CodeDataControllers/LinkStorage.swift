//
//  UrlStorage.swift
//  Urly
//
//  Created by Mattia Righetti on 1/2/22.
//

import os
import Combine
import CoreData

class LinkStorage: NSObject, ObservableObject {
    var links = CurrentValueSubject<[Link], Never>([])
    static let shared = LinkStorage()
    private let linkFetchController: NSFetchedResultsController<Link>
    
    private override init() {
        linkFetchController = NSFetchedResultsController(
            fetchRequest: Link.Request.all.rawValue,
            managedObjectContext: PersistenceController.shared.container.viewContext,
            sectionNameKeyPath: nil,
            cacheName: nil
        )
        
        super.init()
        
        linkFetchController.delegate = self
        
        do {
            try linkFetchController.performFetch()
            links.value = linkFetchController.fetchedObjects ?? []
        } catch {
            NSLog("Error: could not fetch tags")
        }
    }
    
    func add(url:String, ogTitle: String?, ogDescription: String?, ogImageUrl: String?, note: String, starred: Bool, unread: Bool, group: Group?, tags: Set<Tag>?) {
        let link = Link(context: PersistenceController.shared.container.viewContext)
        link.setValue(UUID(), forKey: "id")
        link.setValue(url, forKey: "url")
        link.setValue(ogTitle, forKey: "ogTitle")
        link.setValue(ogDescription, forKey: "ogDescription")
        link.setValue(ogImageUrl, forKey: "ogImageUrl")
        link.setValue(note, forKey: "note")
        link.setValue(starred, forKey: "starred")
        link.setValue(unread, forKey: "unread")
        link.setValue(group, forKey: "group")
        link.setValue(tags, forKey: "tags")
        link.setValue(Int(Date.now.timeIntervalSince1970), forKey: "createdAt")
        link.setValue(Int(Date.now.timeIntervalSince1970), forKey: "updatedAt")
        
        os_log(.info, "Saving Tag: \(link)")

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

extension LinkStorage: NSFetchedResultsControllerDelegate {
    public func controllerDidChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {
        guard let links = controller.fetchedObjects as? [Link] else { return }
        self.links.value = links
    }
}