//
//  Database.swift
//  Ulry
//
//  Created by Mattia Righetti on 3/3/22.
//

import os
import FMDB
import FMDBMigrationManager

public protocol DatabaseControllerDelegate: AnyObject {
    func databaseController(_ databaseController: Database, didInsert link: Link)
    func databaseController(_ databaseController: Database, didInsert links: [Link])
    func databaseController(_ databaseController: Database, didInsert tag: Tag)
    func databaseController(_ databaseController: Database, didInsert tags: [Tag])
    func databaseController(_ databaseController: Database, didInsert group: Group)
    func databaseController(_ databaseController: Database, didInsert groups: [Group])
    func databaseController(_ databaseController: Database, didUpdate link: Link)
    func databaseController(_ databaseController: Database, didUpdate links: [Link])
    func databaseController(_ databaseController: Database, didUpdate group: Group)
    func databaseController(_ databaseController: Database, didUpdate groups: [Group])
    func databaseController(_ databaseController: Database, didUpdate tag: Tag)
    func databaseController(_ databaseController: Database, didUpdate tags: [Tag])
    func databaseController(_ databaseController: Database, didDelete link: Link)
    func databaseController(_ databaseController: Database, didDelete links: [Link])
    func databaseController(_ databaseController: Database, didDelete group: Group)
    func databaseController(_ databaseController: Database, didDelete groups: [Group])
    func databaseController(_ databaseController: Database, didDelete tag: Tag)
    func databaseController(_ databaseController: Database, didDelete tags: [Tag])
}

extension DatabaseControllerDelegate {
    func databaseController(_ databaseController: Database, didInsert link: Link) {}
    func databaseController(_ databaseController: Database, didInsert links: [Link]) {}
    func databaseController(_ databaseController: Database, didInsert tag: Tag) {}
    func databaseController(_ databaseController: Database, didInsert tags: [Tag]) {}
    func databaseController(_ databaseController: Database, didInsert group: Group) {}
    func databaseController(_ databaseController: Database, didInsert groups: [Group]) {}
    func databaseController(_ databaseController: Database, didUpdate link: Link) {}
    func databaseController(_ databaseController: Database, didUpdate links: [Link]) {}
    func databaseController(_ databaseController: Database, didUpdate group: Group) {}
    func databaseController(_ databaseController: Database, didUpdate groups: [Group]) {}
    func databaseController(_ databaseController: Database, didUpdate tag: Tag) {}
    func databaseController(_ databaseController: Database, didUpdate tags: [Tag]) {}
    func databaseController(_ databaseController: Database, didDelete link: Link) {}
    func databaseController(_ databaseController: Database, didDelete links: [Link]) {}
    func databaseController(_ databaseController: Database, didDelete group: Group) {}
    func databaseController(_ databaseController: Database, didDelete groups: [Group]) {}
    func databaseController(_ databaseController: Database, didDelete tag: Tag) {}
    func databaseController(_ databaseController: Database, didDelete tags: [Tag]) {}
}

public final class Database {
    var db: FMDatabase
    weak var delegate: DatabaseControllerDelegate?
    static var shared: Database = Database()
    
    public init(inMemory: Bool = false) {
        if inMemory {
            self.db = FMDatabase()
            self.db.open()
            self.runMigrations_v2()
        } else {
            let fileURL = try! FileManager.default
                .url(for: .applicationSupportDirectory, in: .userDomainMask, appropriateFor: nil, create: true)
                .appendingPathComponent("ulry.sqlite")
            
            self.db = FMDatabase(url: fileURL)
            self.db.open()
            
            runMigrations_v2()
        }
    }
    
    func runMigration_v1() {
        let manager = FMDBMigrationManager(database: self.db, migrationsBundle: .main)!
        if !manager.hasMigrationsTable {
            try! manager.createMigrationsTable()
        }
        
        do {
            try manager.migrateDatabase(toVersion: UInt64.max, progress: { _ in })
        } catch {
            fatalError("encountered error while running migrations, error was: \(error)")
        }
    }
    
    func runMigrations_v2() {
        self.db.executeStatements(
            """
            -- Activate foreign keys
            create table if not exists category(
                id      text unique,
                name    varchar(50) not null unique,
                icon    varchar(50) not null,
                color   char(6) not null
            );

            create table if not exists tag(
                id            text unique,
                name          varchar(50) not null unique,
                description   text,
                color         char(6) not null
            );

            create table if not exists link(
                id              text unique,
                url             text not null,
                starred         bool not null,
                unread          bool not null,
                note            text,
                color           varchar(7) not null,
                image           text,
                ogTitle         text,
                ogDescription   text,
                ogImageUrl      text,
                created_at      integer not null,
                updated_at      integer not null
            );

            create table if not exists category_link(
                link_id       text not null references link(id) on delete cascade,
                category_id     text not null references category(id) on delete cascade,
                primary key (link_id, category_id)
            );

            create table if not exists tag_link(
                link_id       text not null references link(id) on delete cascade,
                tag_id        text not null references tag(id) on delete cascade,
                primary key (link_id, tag_id)
            );
            """
        )
    }
    
    // MARK: - CREATE
    
    public func insert(_ tag: Tag) -> Bool {
        self.db.beginTransaction()
        
        do {
            try self.db.executeUpdate(
                """
                insert into tag (id, name, description, color)
                values (?, ?, ?, ?)
                """,
                values: [tag.id, tag.name, tag.description_, tag.colorHex]
            )
            self.db.commit()
            delegate?.databaseController(self, didInsert: tag)
            return true
        } catch {
            os_log(.error, "encountered error while inserting tag, error was: %@", error as CVarArg)
            self.db.rollback()
            return false
        }
    }
    
    public func batchInsert(_ tags: [Tag]) -> Bool {
        self.db.beginTransaction()
        
        do {
            for tag in tags {
                try self.db.executeUpdate(
                    """
                    insert into tag (id, name, description, color)
                    values (?, ?, ?, ?)
                    """,
                    values: [tag.id, tag.name, tag.description_, tag.colorHex]
                )
            }
            self.db.commit()
            delegate?.databaseController(self, didInsert: tags)
            return true
        } catch {
            os_log(.error, "encountered error while inserting tag, error was: %@", error as CVarArg)
            self.db.rollback()
            return false
        }
    }
    
    public func insert(_ group: Group) -> Bool {
        self.db.beginTransaction()
        
        do {
            try self.db.executeUpdate(
                """
                insert into category (id, name, icon, color)
                values (?, ?, ?, ?)
                """,
                values: [group.id, group.name, group.iconName, group.colorHex]
            )
            self.db.commit()
            delegate?.databaseController(self, didInsert: group)
            return true
        } catch {
            os_log(.error, "encountered error while inserting category, error was: %@", error as CVarArg)
            self.db.rollback()
            return false
        }
    }
    
    public func batchInsert(_ groups: [Group]) -> Bool {
        self.db.beginTransaction()
        
        do {
            for group in groups {
                try self.db.executeUpdate(
                    """
                    insert into category (id, name, icon, color)
                    values (?, ?, ?, ?)
                    """,
                    values: [group.id, group.name, group.iconName, group.colorHex]
                )
            }
            self.db.commit()
            delegate?.databaseController(self, didInsert: groups)
            return true
        } catch {
            os_log(.error, "encountered error while inserting batch category, error was: %@", error as CVarArg)
            self.db.rollback()
            return false
        }
    }
    
    public func insert(_ link: Link) -> Bool {
        self.db.beginTransaction()
        
        do {
            try self.db.executeUpdate(
                """
                insert into link (id, url, starred, unread, color, created_at, updated_at)
                values (?, ?, ?, ?, ?, ?, ?)
                """,
                values: [link.id, link.url, link.starred, link.unread, link.colorHex, link.createdAt, link.updatedAt]
            )
            
            if let note = link.note {
                try self.db.executeUpdate(
                    """
                    update link
                    set note = ?
                    where id = ?
                    """,
                    values: [note, link.id]
                )
            }
            
            if let base64Image = link.imageBase64Representation {
                try self.db.executeUpdate(
                    """
                    update link
                    set image = ?
                    where id = ?
                    """,
                    values: [base64Image, link.id]
                )
            }
            
            self.db.commit()
            delegate?.databaseController(self, didInsert: link)
            return true
        } catch {
            os_log(.error, "encountered error while inserting link, error was: %@", error as CVarArg)
            self.db.rollback()
            return false
        }
    }
    
    public func batchInsert(_ links: [Link]) -> Bool {
        self.db.beginTransaction()
        
        do {
            for link in links {
                try self.db.executeUpdate(
                    """
                    insert into link (id, url, starred, unread, color, created_at, updated_at)
                    values (?, ?, ?, ?, ?, ?, ?)
                    """,
                    values: [link.id, link.url, link.starred, link.unread, link.colorHex, link.createdAt, link.updatedAt]
                )
                
                if let note = link.note {
                    try self.db.executeUpdate(
                        """
                        update link
                        set note = ?
                        where id = ?
                        """,
                        values: [note, link.id]
                    )
                }
                
                if let base64Image = link.imageBase64Representation {
                    try self.db.executeUpdate(
                        """
                        update link
                        set image = ?
                        where id = ?
                        """,
                        values: [base64Image, link.id]
                    )
                }
            }
            
            self.db.commit()
            delegate?.databaseController(self, didInsert: links)
            return true
        } catch {
            os_log(.error, "encountered error while inserting link, error was: %@", error as CVarArg)
            self.db.rollback()
            return false
        }
    }
    
    // MARK: - READ
    
    public func getAllLinksUUID() -> [String] {
        do {
            var uuids = [String]()
            let res = try self.db.executeQuery("select id from link", values: [])
            while res.next() {
                if let uuid = res.string(forColumn: "id") {
                    uuids.append(uuid)
                }
            }
            return uuids
        } catch {
            os_log(.error, "encountered error while getting uuids, error was: %@", error as CVarArg)
            return []
        }
    }
   
    public func getAllStarredLinksUUID() -> [String] {
        do {
            var uuids = [String]()
            let res = try self.db.executeQuery(
                """
                select id
                from link
                where starred = true
                """,
                values: nil
            )
            while res.next() {
                if let uuid = res.string(forColumn: "id") {
                    uuids.append(uuid)
                }
            }
            return uuids
        } catch {
            os_log(.error, "encountered error while getting starred links: error was %@", error as CVarArg)
            return []
        }
    }
    
    public func getAllUnreadLinksUUID() -> [String] {
        do {
            var uuids = [String]()
            let res = try self.db.executeQuery(
                """
                select id
                from link
                where unread = true
                """,
                values: nil
            )
            while res.next() {
                if let uuid = res.string(forColumn: "id") {
                    uuids.append(uuid)
                }
            }
            return uuids
        } catch {
            os_log(.error, "encountered error while getting unread links: error was %@", error as CVarArg)
            return []
        }
    }
    
    public func getAllLinksUUID(in group: Group) -> [String] {
        do {
            var uuids = [String]()
            let res = try self.db.executeQuery(
                """
                select link_id
                from category_link
                where category_id = ?
                """,
                values: [group.id]
            )
            while res.next() {
                if let uuid = res.string(forColumn: "id") {
                    uuids.append(uuid)
                }
            }
            return uuids
        } catch {
            os_log(.error, "encountered error while getting links in group %@: error was %@", group.name, error as CVarArg)
            return []
        }
    }
    
    public func getAllLinksUUID(in tag: Tag) -> [String] {
        do {
            var uuids = [String]()
            let res = try self.db.executeQuery(
                """
                select link_id
                from tag_link
                where tag_id = ?
                """,
                values: [tag.id]
            )
            while res.next() {
                if let uuid = res.string(forColumn: "id") {
                    uuids.append(uuid)
                }
            }
            return uuids
        } catch {
            os_log(.error, "encountered error while getting links in tag %@: error was %@", tag.name, error as CVarArg)
            return []
        }
    }
    
    public func getAllLinks() -> [Link] {
        do {
            var links = [Link]()
            let res = try self.db.executeQuery(
                """
                select *
                from link
                """,
                values: nil
            )
            while res.next() {
                if let link = Link(from: res) {
                    links.append(link)
                }
            }
            res.close()
            return links
        } catch {
            os_log(.error, "could not retrieve links")
            return [Link]()
        }
    }
    
    public func getLinksIn(_ group: Group) -> [Link] {
        do {
            var links = [Link]()
            let res = try self.db.executeQuery(
                """
                select *
                from link
                where id in (
                    select link_id
                    from folder_link
                    where folder_id = ?
                )
                """,
                values: [group.id]
            )
            while res.next() {
                if let link = Link(from: res) {
                    links.append(link)
                }
            }
            res.close()
            return links
        } catch {
            os_log(.error, "could not retrieve links")
            return [Link]()
        }
    }
    
    public func getLinksIn(_ tag: Tag) -> [Link] {
        do {
            var links = [Link]()
            let res = try self.db.executeQuery(
                """
                select *
                from link
                where id in (
                    select link_id
                    from tags_link
                    where tag_link = ?
                )
                """,
                values: [tag.id]
            )
            while res.next() {
                if let link = Link(from: res) {
                    links.append(link)
                }
            }
            res.close()
            return links
        } catch {
            os_log(.error, "could not retrieve links")
            return [Link]()
        }
    }
    
    public func countLinks() -> Int {
        do {
            var count: Int = 0
            let res = try self.db.executeQuery(
                """
                select count(*)
                from link
                """,
                values: nil
            )
            if res.next() {
                count = Int(res.int(forColumnIndex: 0))
            }
            res.close()
            return count
        } catch {
            os_log(.error, "could not count links in group: %@", error as CVarArg)
            return 0
        }
    }
    
    public func countStarredLinks() -> Int {
        do {
            var count: Int = 0
            let res = try self.db.executeQuery(
                """
                select count(*)
                from link
                where starred = true
                """,
                values: nil
            )
            if res.next() {
                count = Int(res.int(forColumnIndex: 0))
            }
            res.close()
            return count
        } catch {
            os_log(.error, "could not count links in group: %@", error as CVarArg)
            return 0
        }
    }
    
    public func countUnreadLinks() -> Int {
        do {
            var count: Int = 0
            let res = try self.db.executeQuery(
                """
                select count(*)
                from link
                where unread = true
                """,
                values: nil
            )
            if res.next() {
                count = Int(res.int(forColumnIndex: 0))
            }
            res.close()
            return count
        } catch {
            os_log(.error, "could not count links in group: %@", error as CVarArg)
            return 0
        }
    }
    
    public func countLinksIn(_ group: Group) -> Int {
        do {
            var count: Int = 0
            let res = try self.db.executeQuery(
                """
                select count(*)
                from category_link
                where category_id = ?
                """,
                values: [group.id]
            )
            if res.next() {
                count = Int(res.int(forColumnIndex: 0))
            }
            res.close()
            return count
        } catch {
            os_log(.error, "could not count links in group: %@", error as CVarArg)
            return 0
        }
    }
    
    public func countLinksIn(_ tag: Tag) -> Int {
        do {
            var count: Int = 0
            let res = try self.db.executeQuery(
                """
                select count(*)
                from tag_link
                where tag_id = ?
                """,
                values: [tag.id]
            )
            if res.next() {
                count = Int(res.int(forColumnIndex: 0))
            }
            res.close()
            return count
        } catch {
            os_log(.error, "could not count links in group: %@", error as CVarArg)
            return 0
        }
    }
    
    public func getLink(with id: UUID) -> Link? {
        do {
            let res = try self.db.executeQuery(
                """
                select *
                from link
                where id = ?
                """,
                values: [id]
            )
            
            if res.next() {
                return Link(from: res)
            }
            
            return nil
        } catch {
            os_log(.error, "coul not get link: %@", error as CVarArg)
            return nil
        }
    }
    
    public func getAllGroups() -> [Group] {
        do {
            var groups = [Group]()
            let res = try self.db.executeQuery("select * from category", values: nil)
            while res.next() {
                if let category = Group(from: res) {
                    groups.append(category)
                }
            }
            res.close()
            return groups
        } catch {
            os_log(.error, "could not retrieve category: %@", error as CVarArg)
            return []
        }
    }
    
    public func getGroup(with id: UUID) -> Group? {
        do {
            let res = try self.db.executeQuery("select * from category where id = ?", values: [id])
            if res.next() {
                return Group(from: res)
            }
            return nil
        } catch {
            os_log(.error, "error retrieving group: %@", error as CVarArg)
            return nil
        }
    }
    
    public func getAllTags() -> [Tag] {
        do {
            var tags = [Tag]()
            let res = try self.db.executeQuery("select * from tag", values: nil)
            while res.next() {
                if let tag = Tag(from: res) {
                    tags.append(tag)
                }
            }
            res.close()
            return tags
        } catch {
            os_log(.error, "could not retrieve tags, error was: %@", error as CVarArg)
            return []
        }
    }
    
    public func getTag(with id: UUID) -> Tag? {
        do {
            let res = try self.db.executeQuery("select * from tag where id = ?", values: [id])
            if res.next() {
                return Tag(from: res)
            }
            return nil
        } catch {
            os_log(.error, "error retrieving tag: %@", error as CVarArg)
            return nil
        }
    }
    
    // MARK: - UPDATE
    
    public func update(_ link: Link) -> Bool {
        self.db.beginTransaction()
        
        do {
            try self.db.executeUpdate(
                """
                update link
                set url = ?, starred = ?, unread = ?, color = ?, note = ?,
                    updated_at = ?, ogTitle = ?, ogImageUrl = ?, ogDescription = ?
                where id = ?
                """,
                values: [
                    link.url, link.starred, link.unread,
                    link.colorHex, link.note as Any, Int32(Date.now.timeIntervalSince1970),
                    link.ogTitle as Any, link.ogImageUrl as Any, link.ogDescription as Any,
                    link.id
                ]
            )
            
            if let note = link.note {
                try self.db.executeUpdate("update link set note = ? where id = ?", values: [note, link.id])
            }
            
            self.db.commit()
            delegate?.databaseController(self, didUpdate: link)
            return true
        } catch {
            os_log(.error, "encountered error while updateing link, error was: %@", error as CVarArg)
            self.db.rollback()
            return false
        }
    }
    
    public func update(_ tag: Tag) -> Bool {
        do {
            try self.db.executeUpdate(
                """
                update tag
                set name = ?, description = ?, color = ?
                where id = ?
                """,
                values: [tag.name, tag.description_, tag.colorHex, tag.id]
            )
            self.db.commit()
            delegate?.databaseController(self, didUpdate: tag)
            return true
        } catch {
            os_log(.error, "encountered error while inserting tag, error was: %@", error as CVarArg)
            self.db.rollback()
            return false
        }
    }
    
    public func update(_ group: Group) -> Bool {
        do {
            try self.db.executeUpdate(
                """
                update category
                set name = ?, icon = ?, color = ?
                where id = ?
                """,
                values: [group.name, group.iconName, group.colorHex, group.id]
            )
            self.db.commit()
            delegate?.databaseController(self, didUpdate: group)
            return true
        } catch {
            os_log(.error, "encountered error while inserting group, error was: %@", error as CVarArg)
            self.db.rollback()
            return false
        }
    }
    
    // MARK: - DELETE
    
    public func delete(_ link: Link) {
        self.db.executeUpdate("delete from link where id = ?", withArgumentsIn: [link.id])
        delegate?.databaseController(self, didDelete: link)
    }
    
    public func delete(_ group: Group) {
        self.db.executeUpdate("delete from category where id = ?", withArgumentsIn: [group.id])
        delegate?.databaseController(self, didDelete: group)
    }
    
    public func delete(_ tag: Tag) {
        self.db.executeUpdate("delete from tag where id = ?", withArgumentsIn: [tag.id])
        delegate?.databaseController(self, didDelete: tag)
    }
}
