//
//  JSONDumpHelper.swift
//  Ulry
//
//  Created by Mattia Righetti on 1/22/22.
//

import Foundation
import MobileCoreServices
import CoreData

fileprivate struct Dump: Codable {
    var version: String?
    var links: [LinkCodable]?
    var groups: [GroupCodable]?
    var tags: [TagCodable]?
}

protocol JSONDumpHelperDelegate {
    func helper(_: JSONDumpHelper, didFinishFetching: [Link])
}

struct JSONDumpHelper {
    
    var delegate: JSONDumpHelperDelegate?
    
    func dumpAllToDocumentFile(
        with filemanager: FileManager = .default,
        encoder: JSONEncoder = JSONEncoder()
    ) throws {
        let context = CoreDataStack.shared.managedContext
        let links = try context.fetch(Link.Request.all.fetchRequest)
        let groups = try context.fetch(Group.Request.all.fetchRequest)
        let tags = try context.fetch(Tag.Request.all.fetchRequest)
        
        let linksCodable = links.map { LinkCodable(from: $0) }
        let groupsCodable = groups.map { GroupCodable(from: $0) }
        let tagsCodable = tags.map { TagCodable(from: $0) }
        
        let dump = Dump(links: linksCodable, groups: groupsCodable, tags: tagsCodable)

        encoder.outputFormatting = .prettyPrinted
        
        let data = try encoder.encode(dump)
        let json = String(data: data, encoding: .utf8)
        
        let file = "Ulry-\(UUID()).json"
        let dir = filemanager.urls(for: .documentDirectory, in: .userDomainMask).first!
        let fileUrl = dir.appendingPathComponent(file)
        
        try json?.write(to: fileUrl, atomically: false, encoding: .utf8)
    }
    
    func loadFromFile(
        with filemanager: FileManager = .default,
        from url: URL,
        decoder: JSONDecoder = JSONDecoder(),
        context: NSManagedObjectContext = CoreDataStack.shared.managedContext,
        dataFetcher: DataFetcher = DataFetcher()
    ) throws {
        guard FileManager.default.fileExists(atPath: url.path) else { return }
        
        let data = try Data(contentsOf: url)
        let dump = try decoder.decode(Dump.self, from: data)
        
        var tagsHash: [UUID:Tag] = [:]
        if let tagsCodable = dump.tags {
            for tagCodable in tagsCodable {
                let tag = Tag(context: context)
                tag.id = tagCodable.id
                tag.name = tagCodable.name
                tag.colorHex = tagCodable.colorHex
                
                tagsHash[tag.id] = tag
            }
        }
        
        var groupHash: [UUID:Group] = [:]
        if let groupsCodable = dump.groups {
            for groupCodable in groupsCodable {
                let group = Group(context: context)
                group.id = groupCodable.id
                group.name = groupCodable.name
                group.colorHex = groupCodable.colorHex
                group.iconName = groupCodable.iconName
                
                groupHash[group.id] = group
            }
        }
        
        var links: [Link] = []
        if let linksCodable = dump.links {
            for linkCodable in linksCodable {
                let link = Link(context: context)
                link.id = linkCodable.id
                link.url = linkCodable.url
                link.createdAt = linkCodable.createdAt
                link.updatedAt = linkCodable.updatedAt
                link.colorHex = linkCodable.colorHex
                link.note = linkCodable.note
                link.starred = linkCodable.starred
                link.unread = linkCodable.unread
                
                if let uuidGroup = linkCodable.group?.id {
                    link.group = groupHash[uuidGroup]
                }
                
                if let tags = linkCodable.tags {
                    link.tags = Set<Tag>()
                    for tagUUID in tags.map({ $0.id }) {
                        link.tags?.insert(tagsHash[tagUUID]!)
                    }
                }
                
                links.append(link)
            }
        }
        
        dataFetcher.fetchData(for: links, completion: {
            delegate?.helper(self, didFinishFetching: links)
        })
    }
}
