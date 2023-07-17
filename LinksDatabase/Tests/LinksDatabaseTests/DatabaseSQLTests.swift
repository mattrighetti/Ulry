//
//  File.swift
//  
//
//  Created by Matt on 15/12/2022.
//  Copyright © 2022 Mattia Righetti. All rights reserved.
//

import FMDB
import Links
import XCTest
@testable import LinksDatabase

let statements = """
    CREATE TABLE IF NOT EXISTS category (id text not null primary key, name varchar(50) not null, icon varchar(50) not null, color char(7) not null);
    CREATE TABLE IF NOT EXISTS tag (id text not null primary key, name varchar(50) not null, color char(7) not null);
    CREATE TABLE IF NOT EXISTS link (id text not null primary key, url text not null, starred bool not null default false, unread bool not null default true, note text, archived bool not null default false, color char(7) not null, ogTitle text, ogDescription text, ogImageUrl text, created_at integer not null, updated_at integer not null);
    CREATE TABLE IF NOT EXISTS category_link (link_id text not null, category_id text not null, primary key (link_id, category_id));
    CREATE TABLE IF NOT EXISTS tag_link (link_id text not null, tag_id text not null, primary key (link_id, tag_id));
    CREATE VIRTUAL TABLE if not EXISTS search USING fts4 (id, url, title, description);
    CREATE TABLE if not EXISTS migrations(version int primary key);
    CREATE TRIGGER if not EXISTS on_link_update_update_lookup AFTER UPDATE ON link BEGIN update search set title = NEW.ogTitle, url = NEW.url, description = NEW.ogDescription where id = NEW.id; END;
    CREATE TRIGGER if not EXISTS on_link_insert_add_lookup AFTER INSERT ON link BEGIN insert into search values (NEW.id, NEW.url, NEW.ogTitle, NEW.ogDescription); END;
    CREATE TRIGGER if not EXISTS on_link_delete_delete_from_tag_and_category AFTER DELETE ON link BEGIN delete from category_link where link_id = OLD.id; delete from tag_link where link_id = OLD.id; delete from search where id = OLD.id; END;
    CREATE TRIGGER if not EXISTS on_category_delete AFTER DELETE ON category BEGIN delete from category_link where category_id = OLD.id; END;
    CREATE TRIGGER if not EXISTS on_tag_delete AFTER DELETE ON tag BEGIN delete from tag_link where tag_id = OLD.id; END;
    """

class DatabaseSQLTests: XCTestCase {
    var database: FMDatabase {
        let db = FMDatabase()
        guard db.open() else { fatalError() }
        statements.enumerateLines { line, stop in
            if line.lowercased().hasPrefix("create") {
                db.executeStatements(line)
            }
        }
        return db
    }

    func testExistsLink() {
        let db = database
        let url = "https://example.com"

        XCTAssertFalse(sql_existsLink(url: url, db))
        sql_insert(Link(url: url), db)
        XCTAssertTrue(sql_existsLink(url: url, db))
    }

    func testExistsGroup() {
        let db = database

        let group = Group(colorHex: "#333333", iconName: "name", name: "somename")

        XCTAssertFalse(sql_existsGroup(name: group.name, db))
        sql_insert(group, db)
        XCTAssertTrue(sql_existsGroup(name: group.name, db))
    }

    func testExistsTag() {
        let db = database

        let tag = Tag(colorHex: "#aaaaaa", name: "somename")

        XCTAssertFalse(sql_existsTag(name: tag.name, db))
        sql_insert(tag, db)
        XCTAssertTrue(sql_existsTag(name: tag.name, db))
    }

    func testLinkInsert() {
        let db = database
        let links = [
            Link(url: "https://example1.com"),
            Link(url: "https://example2.com"),
            Link(url: "https://example3.com"),
            Link(url: "https://example4.com"),
            Link(url: "https://example5.com"),
            Link(url: "https://example6.com")
        ]

        XCTAssertEqual(0, sql_fetchLinks(db).count)

        for link in links {
            sql_insert(link, db)
        }

        let res = sql_fetchLinks(orderBy: ("created_at", "desc"), db)
        let resUuid = sql_fetchLinkIDs(orderBy: ("created_at", "desc"), db)

        XCTAssertEqual(links.count, res.count)
        XCTAssertEqual(links.count, resUuid.count)
        for i in 0..<res.count {
            XCTAssertEqual(links[i], res[i])
            XCTAssertEqual(links[i].id.uuidString, resUuid[i])
        }
    }

    func testTagInsert() {
        let db = database
        let tags = [
            Tag(colorHex: "#334444", name: "1"),
            Tag(colorHex: "#334444", name: "2"),
            Tag(colorHex: "#334444", name: "3"),
            Tag(colorHex: "#334444", name: "4"),
            Tag(colorHex: "#334444", name: "5"),
            Tag(colorHex: "#334444", name: "6"),
            Tag(colorHex: "#334444", name: "6"), // Duplicates are ok with new migration
            Tag(colorHex: "#334444", name: "5"),
        ].sorted(by: { $0.id.uuidString < $1.id.uuidString })

        XCTAssertEqual(0, sql_fetchAllTags(db).count)

        for tag in tags {
            sql_insert(tag, db)
        }

        let fetched = sql_fetchAllTags(db).sorted(by: { $0.id.uuidString < $1.id.uuidString })
        XCTAssertEqual(tags.count, sql_fetchAllTags(db).count)
        for i in 0..<tags.count {
            XCTAssertEqual(tags[i], fetched[i])
        }
    }

    func testGroupInsert() {
        let db = database
        let groups = [
            Group(colorHex: "#333333", iconName: "iconName", name: "Some Name1"),
            Group(colorHex: "#333333", iconName: "iconName", name: "Some Name2"),
            Group(colorHex: "#333333", iconName: "iconName", name: "Some Name3"),
            Group(colorHex: "#333333", iconName: "iconName", name: "Some Name4"),
            Group(colorHex: "#333333", iconName: "iconName", name: "Some Name5"),
            Group(colorHex: "#333333", iconName: "iconName", name: "Some Name6"),
            Group(colorHex: "#333333", iconName: "iconName", name: "Some Name6"), // Duplicates are ok with new migration
            Group(colorHex: "#333333", iconName: "iconName", name: "Some Name1")
        ].sorted(by: { $0.id.uuidString < $1.id.uuidString })

        for group in groups {
            sql_insert(group, db)
        }

        XCTAssertEqual(groups.count, sql_fetchAllGroups(db).count)

        let fetched = sql_fetchAllGroups(db).sorted(by: { $0.id.uuidString < $1.id.uuidString })
        for i in 0..<groups.count {
            XCTAssertEqual(groups[i], fetched[i])
        }
    }

    func testLinkDelete() {
        let db = database
        var links = [
            Link(url: "https://example1.com"),
            Link(url: "https://example2.com"),
            Link(url: "https://example3.com"),
            Link(url: "https://example4.com"),
            Link(url: "https://example5.com"),
            Link(url: "https://example6.com")
        ]

        XCTAssertEqual(0, sql_fetchLinks(db).count)

        for link in links {
            sql_insert(link, db)
        }

        var deleted = [String]()
        for _ in 0..<2 {
            let link = links.remove(at: 0)
            sql_deleteLink(id: link.id.uuidString, db)
            deleted.append(link.url)
        }

        XCTAssertEqual(4, sql_fetchLinkIDs(db).count)
        XCTAssertEqual(4, sql_fetchLinks(db).count)

        for url in deleted {
            XCTAssertFalse(sql_existsLink(url: url, db))
        }

        for link in links {
            sql_deleteLink(id: link.id.uuidString, db)
        }

        XCTAssertEqual(0, sql_fetchLinkIDs(db).count)
        XCTAssertEqual(0, sql_fetchLinks(db).count)
    }

    func testGroupDelete() {
        let db = database
        let groups = [
            Group(colorHex: "#333333", iconName: "iconName", name: "Some Name1"),
            Group(colorHex: "#333333", iconName: "iconName", name: "Some Name2"),
            Group(colorHex: "#333333", iconName: "iconName", name: "Some Name3"),
            Group(colorHex: "#333333", iconName: "iconName", name: "Some Name4"),
            Group(colorHex: "#333333", iconName: "iconName", name: "Some Name5"),
            Group(colorHex: "#333333", iconName: "iconName", name: "Some Name6")
        ]

        for group in groups {
            sql_insert(group, db)
        }

        for group in groups {
            XCTAssertTrue(sql_existsGroup(name: group.name, db))
        }

        for group in groups {
            sql_deleteGroup(id: group.id.uuidString, db)
        }
    }

    func testTagDelete() {
        let db = database
        let tags = [
            Tag(colorHex: "#334444", name: "1"),
            Tag(colorHex: "#334444", name: "2"),
            Tag(colorHex: "#334444", name: "3"),
            Tag(colorHex: "#334444", name: "4"),
            Tag(colorHex: "#334444", name: "5"),
            Tag(colorHex: "#334444", name: "6")
        ]

        for tag in tags {
            sql_insert(tag, db)
        }

        for tag in tags {
            XCTAssertTrue(sql_existsTag(name: tag.name, db))
        }

        for tag in tags {
            sql_deleteTag(id: tag.id.uuidString, db)
        }
    }

    func testLinkUpdate() {
        let db = database

        sql_insert(Link(url: "https://example.com"), db)
        let link = sql_fetchSingleLink(whereClause: "url = 'https://example.com'", db)
        link.url = "https://example1.com"
        sql_update(link, db)
        XCTAssertFalse(sql_existsLink(url: "https://example.com", db))
        XCTAssertTrue(sql_existsLink(url: "https://example1.com", db))
        XCTAssertEqual(link, sql_fetchSingleLink(whereClause: "url = 'https://example1.com'", db))
    }

    func testGroupUpdate() {
        let db = database

        sql_insert(Group(colorHex: "#333333", iconName: "iconname", name: "name1"), db)
        let group = sql_fetchSingleGroup(whereClause: "name = 'name1'", db)
        group.name = "name2"
        sql_update(group, db)
        XCTAssertFalse(sql_existsGroup(name: "name1", db))
        XCTAssertTrue(sql_existsGroup(name: "name2", db))
    }

    func testTagUpdate() {
        let db = database

        sql_insert(Tag(colorHex: "#33aaff", name: "name1"), db)
        let tag = sql_fetchSingleTag(whereClause: "name = 'name1'", db)
        tag.name = "name2"
        sql_update(tag, db)
        XCTAssertFalse(sql_existsTag(name: "name1", db))
        XCTAssertTrue(sql_existsTag(name: "name2", db))
    }

    func testLinkUpdateWithTagsAndGroups() {
        let db = database
        let groups = [
            Group(colorHex: "#aaffaa", iconName: "icon1", name: "name1"),
            Group(colorHex: "#ffaaff", iconName: "icon2", name: "name2"),
        ]

        let tags = [
            Tag(colorHex: "#aaffaa", name: "tag1"),
            Tag(colorHex: "#aaffaa", name: "tag2"),
            Tag(colorHex: "#aaffaa", name: "tag3"),
            Tag(colorHex: "#aaffaa", name: "tag4"),
            Tag(colorHex: "#aaffaa", name: "tag5"),
            Tag(colorHex: "#aaffaa", name: "tag6"),
            Tag(colorHex: "#aaffaa", name: "tag7")
        ]

        for tag in tags {
            sql_insert(tag, db)
        }

        for group in groups {
            sql_insert(group, db)
        }

        let link = Link(url: "https://example.com")
        link.group = groups[0]
        link.tags = Set(tags[0...2])

        sql_insert(link, db)
        XCTAssertTrue(sql_existsLink(url: "https://example.com", db))
        let fetchedLink1 = sql_fetchSingleLink(whereClause: "url = '\(link.url)'", db)
        XCTAssertEqual(link, fetchedLink1)

        link.group = nil
        link.tags = nil
        sql_update(link, db)
        let fetchedLink2 = sql_fetchSingleLink(whereClause: "url = '\(link.url)'", db)
        XCTAssertEqual(link, fetchedLink2)

        link.tags = Set(tags[0...1])
        sql_update(link, db)
        let fetchedLink3 = sql_fetchSingleLink(whereClause: "url = '\(link.url)'", db)
        XCTAssertEqual(link, fetchedLink3)

        link.tags = nil
        link.group = groups[1]
        sql_update(link, db)
        let fetchedLink4 = sql_fetchSingleLink(whereClause: "url = '\(link.url)'", db)
        XCTAssertEqual(link, fetchedLink4)
    }

    func testGroupUpdateCascadesToLink() {
        let db = database

        let group = Group(colorHex: "#afafaf", iconName: "icon", name: "name")
        let link = Link(url: "https://example.com")
        link.group = group

        sql_insert(group, db)
        sql_insert(link, db)
        group.name = "othername"
        sql_update(group, db)

        let fetchedLink = sql_fetchSingleLink(whereClause: "url = '\(link.url)'", db)
        XCTAssertEqual("othername", fetchedLink.group!.name)
    }

    func testTagUpdateCascadesToLink() {
        let db = database

        let tags = [
            Tag(colorHex: "#aaffaa", name: "tag1"),
            Tag(colorHex: "#aafdaa", name: "tag2"),
            Tag(colorHex: "#aafaaa", name: "tag3"),
        ]
        let link = Link(url: "https://example.com")
        link.tags = Set(tags)

        for tag in tags {
            sql_insert(tag, db)
        }
        sql_insert(link, db)

        tags[0].name = "tag4"
        tags[1].name = "tag1"
        sql_update(tags[0], db)
        sql_update(tags[1], db)

        let fetchedLink = sql_fetchSingleLink(whereClause: "url = '\(link.url)'", db)
        XCTAssertTrue(fetchedLink.tags!.contains(tags[0]))
        XCTAssertTrue(fetchedLink.tags!.contains(tags[1]))
        XCTAssertEqual(tags[1], fetchedLink.tags!.first(where: { $0.name == "tag1" }))
        XCTAssertEqual(tags[0], fetchedLink.tags!.first(where: { $0.name == "tag4" }))
    }

    func testTagDeletionCascadesToLink() {
        let db = database
        let tags = [
            Tag(colorHex: "#aaffaa", name: "tag1"),
            Tag(colorHex: "#aafdaa", name: "tag2"),
            Tag(colorHex: "#aafaaa", name: "tag3"),
        ]
        let link = Link(url: "https://example.com")
        link.tags = Set(tags)

        for tag in tags {
            sql_insert(tag, db)
        }
        sql_insert(link, db)

        sql_deleteTag(id: tags[0].id.uuidString, db)
        let fetchedLink1 = sql_fetchSingleLink(whereClause: "url = '\(link.url)'", db)
        XCTAssertEqual(2, fetchedLink1.tags!.count)

        sql_deleteTag(id: tags[1].id.uuidString, db)
        let fetchedLink2 = sql_fetchSingleLink(whereClause: "url = '\(link.url)'", db)
        XCTAssertEqual(1, fetchedLink2.tags!.count)

        sql_deleteTag(id: tags[2].id.uuidString, db)
        let fetchedLink3 = sql_fetchSingleLink(whereClause: "url = '\(link.url)'", db)
        XCTAssertNil(fetchedLink3.tags)
    }

    func testGroupDeletionCascadesToLink() {
        let db = database
        let group = Group(colorHex: "#aaaaaa", iconName: "icon", name: "name")
        let link = Link(url: "https://example.com")
        link.group = group

        sql_insert(group, db)
        sql_insert(link, db)
        let fetchedLink1 = sql_fetchSingleLink(whereClause: "url = '\(link.url)'", db)
        XCTAssertEqual(group, fetchedLink1.group)

        sql_deleteGroup(id: group.id.uuidString, db)
        let fetchedLink2 = sql_fetchSingleLink(whereClause: "url = '\(link.url)'", db)
        XCTAssertNil(fetchedLink2.group)
    }

}
