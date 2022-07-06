//
//  UlryTests.swift
//  UlryTests
//
//  Created by Mattia Righetti on 1/9/22.
//

import XCTest
@testable import Ulry

class DatabaseTests: XCTestCase {
    var database = Database(inMemory: true)
    
    func testLinkInsertEqual() {
        let link = Link(url: "https://1.com", note: nil)
        let res = self.database.insert(link)
        let sameLink = self.database.getLink(with: link.id)
        
        XCTAssertTrue(res)
        XCTAssertEqual(link, sameLink)
    }
    
    func testPerformanceMultipleLinkInsert() {
        var links: [Link] = []
        
        for i in 0..<1000 {
            let link = Link(url: "https://\(i).com", note: "")
            links.append(link)
        }
       
        // fast
        measure {
            _ = self.database.batchInsert(links)
        }
    }
    
    func testUpdateLink() {
        let link = Link(url: "https://example.com", note: "This is a not")
        XCTAssertTrue(self.database.insert(link))
        
        link.note = "This is a note"
        link.ogImageUrl = "https://example.com/image.jpeg"
        link.ogTitle = "Title"
        link.ogDescription = nil
        XCTAssertTrue(self.database.update(link))
        
        let updatedLink = self.database.getLink(with: link.id)
        XCTAssertTrue(link == updatedLink)
    }
    
    func testUpdateTag() {
        let id = UUID()
        let tag = Tag(id: id, colorHex: "#ffffff", description: "Tag description", name: "generic")
        _ = self.database.insert(tag)
        
        let n_tag = self.database.getTag(with: id)
        XCTAssertNotNil(n_tag)
        
        n_tag!.colorHex = "#ffaaff"
        n_tag!.description_ = "this is a new tag"
        _ = self.database.update(tag)
        
        XCTAssertEqual(n_tag?.colorHex, "#ffaaff")
        XCTAssertEqual(n_tag?.description_, "this is a new tag")
    }
    
    func testInsertWithTag() {
        let tag = Tag(id: UUID(), colorHex: "#aaaaaa", description: "", name: "tag")
        XCTAssertTrue(self.database.insert(tag))
        
        let link = Link(url: "https://simpletest.com", note: nil)
        link.tags = Set([tag])
        XCTAssertTrue(self.database.insert(link))
        
        let uuids = self.database.getAllLinksUUID(in: tag)
        XCTAssertEqual(1, uuids.count)
        XCTAssertEqual(uuids[0], link.id.uuidString)
        
        XCTAssertTrue(self.database.delete(link))
        XCTAssertEqual(0, self.database.getAllLinksUUID(in: tag).count)
    }
    
    func testUpdateLinkWithTagRemoval() {
        let tag1 = Tag(id: UUID(), colorHex: "#aaaaaa", description: "", name: "another tag")
        let tag2 = Tag(id: UUID(), colorHex: "#aaddbb", description: "", name: "very similar tag")
        XCTAssertTrue(self.database.batchInsert([tag1, tag2]))
        
        let link = Link(url: "https://anothersimpletest.com", note: nil)
        link.tags = Set([tag1, tag2])
        XCTAssertTrue(self.database.insert(link))
        
        let uuid1 = self.database.getAllLinksUUID(in: tag1)
        XCTAssertEqual(1, uuid1.count)
        XCTAssertEqual(uuid1[0], link.id.uuidString)
        
        let uuid2 = self.database.getAllLinksUUID(in: tag2)
        XCTAssertEqual(1, uuid2.count)
        XCTAssertEqual(uuid2[0], link.id.uuidString)
        
        link.tags = Set([tag1])
        XCTAssertTrue(self.database.update(link))
        XCTAssertEqual(0, self.database.getAllLinksUUID(in: tag2).count)
        XCTAssertEqual(1, self.database.getAllLinksUUID(in: tag1).count)
    }
}
