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
    
    func add(
        url: String, ogTitle: String?, ogDescription: String?, ogImageUrl: String?, colorHex: String,
        note: String, starred: Bool, unread: Bool, imageData: Data?, group: Group?, tags: Set<Tag>?
    ) {
        let link = Link(context: PersistenceController.shared.container.viewContext)
        link.setValue(UUID(), forKey: "id")
        link.setValue(url, forKey: "url")
        link.setValue(ogTitle, forKey: "ogTitle")
        link.setValue(ogDescription, forKey: "ogDescription")
        link.setValue(ogImageUrl, forKey: "ogImageUrl")
        link.setValue(note, forKey: "note")
        link.setValue(starred, forKey: "starred")
        link.setValue(unread, forKey: "unread")
        link.setValue(imageData, forKey: "imageData")
        link.setValue(colorHex, forKey: "colorHex")
        link.setValue(group, forKey: "group")
        link.setValue(tags, forKey: "tags")
        link.setValue(Int(Date.now.timeIntervalSince1970), forKey: "createdAt")
        link.setValue(Int(Date.now.timeIntervalSince1970), forKey: "updatedAt")

        saveContext()
        
        DispatchQueue.global(qos: .userInitiated).async {
            os_log(.info, "fetching image for link")
            guard let ogImageUrl = ogImageUrl, let url = URL(string: ogImageUrl) else {
                os_log(.debug, "invalid imageUrl or URL")
                return
            }
            let task = URLSession.shared.dataTask(with: url) { [unowned self] data, response, error in
                os_log(.info, "checking received data")
                guard let data = data else { return }
                os_log(.info, "got data, saving")
                link.setValue(data, forKey: "imageData")
                self.saveContext()
            }
            task.resume()
        }
    }
    
    func update(
        link: Link, url: String, ogTitle: String?, ogDescription: String?, ogImageUrl: String?, colorHex: String,
        note: String, starred: Bool, unread: Bool, imageData: Data?, group: Group?, tags: Set<Tag>?
    ) {
        link.setValue(url, forKey: "url")
        link.setValue(ogTitle, forKey: "ogTitle")
        link.setValue(ogDescription, forKey: "ogDescription")
        link.setValue(ogImageUrl, forKey: "ogImageUrl")
        link.setValue(note, forKey: "note")
        link.setValue(starred, forKey: "starred")
        link.setValue(unread, forKey: "unread")
        link.setValue(imageData, forKey: "imageData")
        link.setValue(colorHex, forKey: "colorHex")
        link.setValue(group, forKey: "group")
        link.setValue(tags, forKey: "tags")
        link.setValue(Int(Date.now.timeIntervalSince1970), forKey: "createdAt")
        link.setValue(Int(Date.now.timeIntervalSince1970), forKey: "updatedAt")
        
        saveContext()
        
        DispatchQueue.global(qos: .userInitiated).async {
            os_log(.info, "fetching image for link")
            guard let ogImageUrl = ogImageUrl, let url = URL(string: ogImageUrl) else {
                os_log(.debug, "invalid imageUrl or URL")
                return
            }
            let task = URLSession.shared.dataTask(with: url) { [unowned self] data, response, error in
                os_log(.info, "checking received data")
                guard let data = data else { return }
                os_log(.info, "got data, saving")
                link.setValue(data, forKey: "imageData")
                self.saveContext()
            }
            task.resume()
        }
    }
    
    func toggleStar(link: Link) {
        link.setValue(!link.starred, forKey: "starred")
        saveContext()
    }
    
    func toggleRead(link: Link) {
        link.setValue(!link.unread, forKey: "unread")
        saveContext()
    }
    
    func delete(uuid: UUID) {
        let fetchedLink = Link.fetchRequest(withUUID: uuid)
        
        do {
            guard let link = try PersistenceController.shared.container.viewContext.fetch(fetchedLink).first else { return }
            PersistenceController.shared.container.viewContext.delete(link)
            saveContext()
        } catch {
            os_log(.error, "cannot delete link with UUID: \(uuid)")
        }
    }
    
    func delete(link: Link) {
        PersistenceController.shared.container.viewContext.delete(link)
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
