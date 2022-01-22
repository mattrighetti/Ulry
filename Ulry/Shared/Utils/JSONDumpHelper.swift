//
//  JSONDumpHelper.swift
//  Ulry
//
//  Created by Mattia Righetti on 1/22/22.
//

import Foundation
import MobileCoreServices

fileprivate struct Dump: Codable {
    var version: String?
    var links: [LinkCodable]?
    var groups: [GroupCodable]?
    var tags: [TagCodable]?
}

struct JSONDumpHelper {
    static func dumpAllToDocumentFile(
        with filemanager: FileManager = .default,
        encoder: JSONEncoder = JSONEncoder()
    ) {
        let context = CoreDataStack.shared.managedContext
        let links = try? context.fetch(Link.Request.all.fetchRequest)
        let groups = try? context.fetch(Group.Request.all.fetchRequest)
        let tags = try? context.fetch(Tag.Request.all.fetchRequest)
        
        let linksCodable = links?.map { LinkCodable(from: $0) }
        let groupsCodable = groups?.map { GroupCodable(from: $0) }
        let tagsCodable = tags?.map { TagCodable(from: $0) }
        
        let dump = Dump(links: linksCodable, groups: groupsCodable, tags: tagsCodable)

        encoder.outputFormatting = .prettyPrinted
        
        do {
            let data = try encoder.encode(dump)
            let json = String(data: data, encoding: .utf8)
            
            let file = "Ulry-\(UUID()).json"
            let dir = filemanager.urls(for: .documentDirectory, in: .userDomainMask).first!
            let fileUrl = dir.appendingPathComponent(file)
            
            try json?.write(to: fileUrl, atomically: false, encoding: .utf8)
            
        } catch {
            print(error)
        }
    }
    
    static func loadFromFile(
        with filemanager: FileManager = .default,
        from url: URL,
        decoder: JSONDecoder = JSONDecoder()
    ) {
        if FileManager.default.fileExists(atPath: url.path) {
            print("File exists")
            let data = try! Data(contentsOf: url)
            let dump = try? decoder.decode(Dump.self, from: data)
            fatalError()
        }
    }
}
