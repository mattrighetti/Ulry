//
//  JSONDumpHelper.swift
//  Ulry
//
//  Created by Mattia Righetti on 1/22/22.
//

import os
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
    func helper(_: JSONDumpHelper, didFinishExporting links: [Link])
    func helper(_: JSONDumpHelper, didFinishFetching links: [Link])
}

struct JSONDumpHelper {
    static let pointsOfInterest = OSLog(subsystem: "com.mattrighetti.Ulry", category: .pointsOfInterest)
    var delegate: JSONDumpHelperDelegate?
    
    func dumpAllToDocumentFile(
        with filemanager: FileManager = .default,
        encoder: JSONEncoder = JSONEncoder()
    ) throws {
        let links = Database.shared.getAllLinks()
        let groups = Database.shared.getAllGroups()
        let tags = Database.shared.getAllTags()
        
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
        delegate?.helper(self, didFinishExporting: links)
    }
    
    func loadFromFile(
        with filemanager: FileManager = .default,
        from url: URL,
        decoder: JSONDecoder = JSONDecoder()
    ) {
        os_signpost(.begin, log: JSONDumpHelper.pointsOfInterest, name: "loadFromFile")
        
        let data = try! Data(contentsOf: url)
        let dump = try! decoder.decode(Dump.self, from: data)
        
        var tags: [Tag] = []
        if let tagsCodable = dump.tags {
            for tagCodable in tagsCodable {
                let tag = Tag(id: tagCodable.id, colorHex: tagCodable.colorHex, name: tagCodable.name)
                tags.append(tag)
            }
        }
        
        var groups: [Group] = []
        if let groupsCodable = dump.groups {
            for groupCodable in groupsCodable {
                let group = Group(id: groupCodable.id, colorHex: groupCodable.colorHex, iconName: groupCodable.iconName, name: groupCodable.name, links: nil)
                groups.append(group)
            }
        }
        
        var links: [Link] = []
        if let linksCodable = dump.links {
            for linkCodable in linksCodable {
                let link = Link(url: linkCodable.url)
                link.id = linkCodable.id
                link.createdAt = linkCodable.createdAt
                link.updatedAt = linkCodable.updatedAt
                link.colorHex = linkCodable.colorHex
                link.ogTitle = linkCodable.ogTitle
                link.ogDescription = linkCodable.ogDescription
                link.ogImageUrl = linkCodable.ogImageUrl
                link.note = linkCodable.note
                link.starred = linkCodable.starred
                link.unread = linkCodable.unread
                
                links.append(link)
            }
        }
        
        _ = Database.shared.batchInsert(links)
        _ = Database.shared.batchInsert(groups)
        _ = Database.shared.batchInsert(tags)
    }
}
