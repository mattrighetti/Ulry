//
//  Link.swift
//  Urly
//
//  Created by Mattia Righetti on 12/25/21.
//

import os
import SwiftUI
import CoreData

public class Link: NSManagedObject {
    var hostname: String {
        guard
            let url = URL(string: self.url),
            var hostname = url.host
        else { return "invalid URL" }
        
        if hostname.starts(with: "www.") {
            hostname = hostname.replacingOccurrences(of: "www.", with: "")
        }
        
        return hostname
    }
    
    var color: Color {
        guard let color = Color(hex: self.colorHex) else { return Color(hex: "#333333")! }
        return color
    }
    
    var dateString: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "d MMM yy"
        let date = Date(timeIntervalSince1970: Double(self.createdAt))
        return formatter.string(from: date)
    }
    
    var needsUpdate: Bool = false
    
    func loadMetaData(completion: (() -> Void)?) {
        needsUpdate = false
        
        let link = url.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !link.isEmpty, URL(string: link) != nil else { return }
        
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            do {
                let og = try MetaRod().build(link).og()
                let imgUrl = og.findFirstValue(keys: URL.imageMeta)
                self?.setPrimitiveValue(og.findFirstValue(keys: URL.titleMeta), forKey: #keyPath(Link.ogTitle))
                self?.setPrimitiveValue(og.findFirstValue(keys: URL.descriptionMeta), forKey: #keyPath(Link.ogDescription))
                self?.setPrimitiveValue(imgUrl, forKey: #keyPath(Link.ogImageUrl))
                
                self?.fetchImage()
            } catch {
                os_log(.error, "encountered error while fetching URL data")
            }
        }
    }
    
    func fetchImage() {
        guard let ogImageUrl = self.ogImageUrl, let url = URL(string: ogImageUrl) else { return }
        
        let task = URLSession.shared.dataTask(with: url) { [weak self] data, response, error in
            self?.setPrimitiveValue(data, forKey: #keyPath(Link.imageData))
        }
        task.resume()
    }
    
    convenience init() {
        self.init(context: CoreDataStack.shared.managedContext)
    }
}

extension Link {
    enum Request: RawRepresentable {
        case all
        case starred
        case unread
        case withUuid(uuid: UUID)
        case folder(Group)
        case tag(Tag)
        
        typealias RawValue = NSFetchRequest<Link>
        
        init?(rawValue: NSFetchRequest<Link>) {
            return nil
        }
        
        var rawValue: NSFetchRequest<Link> {
            let sort = [NSSortDescriptor(key: "createdAt", ascending: false)]
            let request: NSFetchRequest<Link>
            
            switch self {
            case .all:
                request = Link.fetchRequest()
            case .starred:
                request = Link.fetchRequest(starred: true)
            case .unread:
                request = Link.fetchRequest(unread: true)
            case .withUuid(uuid: let uuid):
                request = Link.fetchRequest(withUUID: uuid)
            case .folder(let group):
                request = Link.fetchRequest(withGroup: group)
            case .tag(let tag):
                request = Link.fetchRequest(withTag: tag)
            }
            
            request.sortDescriptors = sort
            return request
        }
    }
}
