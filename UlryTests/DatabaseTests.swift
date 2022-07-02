//
//  UlryTests.swift
//  UlryTests
//
//  Created by Mattia Righetti on 1/9/22.
//

import XCTest
@testable import Ulry

class DatabaseTests: XCTestCase {
    var database: Database!
    
    override func setUp() {
        self.database = Database(inMemory: true)
        self.database.db.executeStatements(
            """
            PRAGMA foreign_keys = ON;
            PRAGMA user_version = 1;

            create table category(
                id      text unique,
                name    varchar(50) not null unique,
                icon    varchar(50) not null,
                color   char(6) not null
            );

            create table tag(
                id              text unique,
                name            varchar(50) not null unique,
                description     text,
                color           char(6) not null
            );

            create table link(
                id          text unique,
                url         text not null,
                starred     bool not null,
                unread      bool not null,
                note        text,
                color       char(6) not null,
                image       text,
                created_at  integer not null,
                updated_at  integer not null
            );

            create table folder_link(
                link_id     text not null references link(id) on delete cascade,
                folder_id   text not null references folder(id) on delete cascade,
                primary key (link_id, group_id)
            );

            create table tag_link(
                link_id     text not null references link(id) on delete cascade,
                tag_id      text not null references tag(id) on delete cascade,
                primary key (link_id, tag_id)
            );
            """
        )
    }
    
    func testLinkInsertEqual() {
        let link = Link(url: "https://1.com", note: nil)
        let res = self.database.insert(link)
        let sameLink = self.database.getLink(with: link.id)
        
        XCTAssertTrue(res)
        XCTAssertEqual(self.database.countLinks(), 1)
        XCTAssertEqual(link, sameLink)
    }
    
    func testPerformanceMultipleLinkInsert() {
        var links = [Link]()
        for i in 0..<1000 {
            let link = Link(url: "https://\(i).com", note: "")
            links.append(link)
        }
       
        // slow
        measure {
            for link in links {
                _ = self.database.insert(link)
            }
        }
        
        // fast
        measure {
            _ = self.database.batchInsert(links)
        }
    }
    
    func testUpdateLink() {
        let link = Link(url: "https://example.com", note: "This is a not")
        _ = self.database.insert(link)
        link.note = "This is a note"
        _ = self.database.update(link)
        let updatedLink = self.database.getLink(with: link.id)
        
        XCTAssertEqual(updatedLink!.note, "This is a note")
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
    
    func testDbSpeed() {
        
    }
    
    override func tearDown() {
        self.database = nil
    }
}
