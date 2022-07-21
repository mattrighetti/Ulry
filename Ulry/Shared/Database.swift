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
    private var db: FMDatabase
    
    weak var delegate: DatabaseControllerDelegate?
    
    private(set) static var main = Database()
    private(set) static var external = Database(external: true)
    
    public init(external: Bool = false, inMemory: Bool = false) {
        if inMemory {
            db = FMDatabase()
            db.open()
            runMigration_v1()
            return
        }
        
        let url: URL!
        if external {
            url = URL.storeURL(for: "group.com.mattrighetti.Ulry", databaseName: "urly")
        } else {
            url = try! FileManager.default
                .url(for: .documentDirectory, in: .userDomainMask, appropriateFor: nil, create: true)
                .appendingPathComponent("ulry.sqlite")
        }
        
        db = FMDatabase(url: url)
        db.open()
        print("User version is \(db.userVersion)")
        //runMigrations_v2()
        runMigration_v1()
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
    
    // MARK: - CREATE
    
    public func insert(_ tag: Tag) -> Bool {
        self.db.beginTransaction()
        
        do {
            try self.db.executeUpdate(
                """
                insert into tag (id, name, color)
                values (?, ?, ?)
                """,
                values: [tag.id, tag.name, tag.colorHex]
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
                    insert into tag (id, name, color)
                    values (?, ?, ?)
                    """,
                    values: [tag.id, tag.name, tag.colorHex]
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
            // TODO ogImageUrl, ogDescription and ogTitle are not inserted here
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
            
            if let group = link.group {
                try self.db.executeUpdate(
                    """
                    insert into category_link(link_id, category_id)
                    values (?, ?)
                    """,
                    values: [link.id, group.id]
                )
            }
            
            if let tags = link.tags {
                for t in tags {
                    try self.db.executeUpdate(
                        """
                        insert into tag_link(link_id, tag_id)
                        values (?, ?)
                        """,
                        values: [link.id, t.id]
                    )
                }
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
                
                if let group = link.group {
                    try self.db.executeUpdate(
                        """
                        insert into category_link(link_id, category_id)
                        values (?, ?)
                        """,
                        values: [link.id, group.id]
                    )
                }
                
                if let tags = link.tags {
                    for t in tags {
                        try self.db.executeUpdate(
                            """
                            insert into tag_link(link_id, tag_id)
                            values (?, ?)
                            """,
                            values: [link.id, t.id]
                        )
                    }
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
    
    public func getAllLinksUUID(order: OrderBy) -> [String] {
        do {
            var uuids = [String]()
            let res: FMResultSet!
            
            switch order {
            case .name:
                res = try self.db.executeQuery("select id from link order by ogTitle asc", values: [])
            case .lastUpdated:
                res = try self.db.executeQuery("select id from link order by updated_at desc", values: [])
            case .oldest:
                res = try self.db.executeQuery("select id from link order by created_at asc", values: [])
            case .newest:
                res = try self.db.executeQuery("select id from link order by created_at desc", values: [])
            }
            
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
   
    public func getAllStarredLinksUUID(order: OrderBy) -> [String] {
        do {
            var uuids = [String]()
            let res: FMResultSet!
            
            switch order {
            case .name:
                res = try self.db.executeQuery(
                    """
                    select id
                    from link
                    where starred = true
                    order by ogTitle asc
                    """,
                    values: []
                )
            case .lastUpdated:
                res = try self.db.executeQuery(
                    """
                    select id
                    from link
                    where starred = true
                    order by updated_at desc
                    """,
                    values: []
                )
            case .oldest:
                res = try self.db.executeQuery(
                    """
                    select id
                    from link
                    where starred = true
                    order by created_at asc
                    """,
                    values: []
                )
            case .newest:
                res = try self.db.executeQuery(
                    """
                    select id
                    from link
                    where starred = true
                    order by created_at dasc
                    """,
                    values: []
                )
            }
            
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
    
    public func getAllUnreadLinksUUID(order: OrderBy) -> [String] {
        do {
            var uuids = [String]()
            let res: FMResultSet!
            
            switch order {
            case .name:
                res = try self.db.executeQuery(
                    """
                    select id
                    from link
                    where unread = true
                    order by ogTitle asc
                    """,
                    values: []
                )
            case .lastUpdated:
                res = try self.db.executeQuery(
                    """
                    select id
                    from link
                    where unread = true
                    order by updated_at desc
                    """,
                    values: []
                )
            case .oldest:
                res = try self.db.executeQuery(
                    """
                    select id
                    from link
                    where unread = true
                    order by created_at asc
                    """,
                    values: []
                )
            case .newest:
                res = try self.db.executeQuery(
                    """
                    select id
                    from link
                    where unread = true
                    order by created_at desc
                    """,
                    values: []
                )
            }
            
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
    
    public func getAllLinksUUID(in group: Group, order: OrderBy) -> [String] {
        do {
            var uuids = [String]()
            let res: FMResultSet!
            
            switch order {
            case .name:
                res = try self.db.executeQuery(
                    """
                    select cl.link_id
                    from category_link cl inner join link l on l.id = cl.link_id
                    where category_id = ?
                    order by l.ogTitle desc
                    """,
                    values: [group.id]
                )
            case .lastUpdated:
                res = try self.db.executeQuery(
                    """
                    select cl.link_id
                    from category_link cl inner join link l on l.id = cl.link_id
                    where category_id = ?
                    order by l.updated_at desc
                    """,
                    values: [group.id]
                )
            case .oldest:
                res = try self.db.executeQuery(
                    """
                    select cl.link_id
                    from category_link cl inner join link l on l.id = cl.link_id
                    where category_id = ?
                    order by l.created_at asc
                    """,
                    values: [group.id]
                )
            case .newest:
                res = try self.db.executeQuery(
                    """
                    select cl.link_id
                    from category_link cl inner join link l on l.id = cl.link_id
                    where category_id = ?
                    order by l.created_at desc
                    """,
                    values: [group.id]
                )
            }
            
            while res.next() {
                if let uuid = res.string(forColumn: "link_id") {
                    uuids.append(uuid)
                }
            }
            return uuids
        } catch {
            os_log(.error, "encountered error while getting links in group %@: error was %@", group.name, error as CVarArg)
            return []
        }
    }
    
    public func getAllLinksUUID(in tag: Tag, order: OrderBy) -> [String] {
        do {
            var uuids = [String]()
            let res: FMResultSet!
            
            switch order {
            case .name:
                res = try self.db.executeQuery(
                    """
                    select tg.link_id
                    from tag_link tg inner join link l on l.id = tg.link_id
                    where tag_id = ?
                    order by l.ogTitle desc
                    """,
                    values: [tag.id]
                )
            case .lastUpdated:
                res = try self.db.executeQuery(
                    """
                    select tg.link_id
                    from tag_link tg inner join link l on l.id = tg.link_id
                    where tag_id = ?
                    order by l.updated_at desc
                    """,
                    values: [tag.id]
                )
            case .oldest:
                res = try self.db.executeQuery(
                    """
                    select tg.link_id
                    from tag_link tg inner join link l on l.id = tg.link_id
                    where tag_id = ?
                    order by l.created_at asc
                    """,
                    values: [tag.id]
                )
            case .newest:
                res = try self.db.executeQuery(
                    """
                    select tg.link_id
                    from tag_link tg inner join link l on l.id = tg.link_id
                    where tag_id = ?
                    order by l.created_at desc
                    """,
                    values: [tag.id]
                )
            }
            
            while res.next() {
                if let uuid = res.string(forColumn: "link_id") {
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
                if let link = Link(from: res) {
                    // TODO horrible code
                    link.group = getGroups(of: link).first
                    link.tags = Set(getTags(of: link))
                    return link
                }
                
                return nil
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
    
    public func getGroups(with ids: [UUID]) -> [Group] {
        do {
            var groups = [Group]()
            for id in ids {
                let res = try self.db.executeQuery("select * from category where id = ?", values: [id])
                if res.next(), let group = Group(from: res) {
                    groups.append(group)
                }
            }
            return groups
        } catch {
            os_log(.error, "error retrieving groups: %@", error as CVarArg)
            return []
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
    
    public func getTags(with ids: [UUID]) -> [Tag] {
        do {
            var tags = [Tag]()
            for id in ids {
                let res = try self.db.executeQuery("select * from tag where id = ?", values: [id])
                if res.next(), let tag = Tag(from: res) {
                    tags.append(tag)
                }
            }
            return tags
        } catch {
            os_log(.error, "error retrieving group: %@", error as CVarArg)
            return []
        }
    }
    
    public func getTags(of link: Link) -> [Tag] {
        do {
            var tags = [Tag]()
            let res = try self.db.executeQuery(
                """
                select * from tag where id in (select tag_id from tag_link where link_id = ?)
                """,
                values: [link.id]
            )
            while res.next() {
                tags.append(Tag(from: res)!)
            }
            return tags
        } catch {
            os_log(.error, "encountered error while retrieving tags of link, error was: %@", error as CVarArg)
            return []
        }
    }
    
    public func getGroups(of link: Link) -> [Group] {
        do {
            var groups = [Group]()
            let res = try self.db.executeQuery(
                """
                select * from category where id in (select category_id from category_link where link_id = ?)
                """,
                values: [link.id]
            )
            while res.next() {
                groups.append(Group(from: res)!)
            }
            return groups
        } catch {
            os_log(.error, "encountered error while retrieving tags of link, error was: %@", error as CVarArg)
            return []
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
            
            
            // Delete all tags entries, the only
            // source of truth is the current link
            try self.db.executeUpdate(
                """
                delete from tag_link
                where link_id = ?
                """, values: [link.id]
            )
            
            // Delete all groups entries, the only
            // source of truth is the current link
            try self.db.executeUpdate(
                """
                delete from category_link
                where link_id = ?
                """,
                values: [link.id]
            )
            
            if let tags = link.tags {
                for t in tags {
                    try self.db.executeUpdate("insert into tag_link (link_id, tag_id) values (?, ?)", values: [link.id, t.id])
                }
            }
            
            if let group = link.group {
                try self.db.executeUpdate(
                    """
                    insert into category_link (link_id, category_id)
                    values (?, ?)
                    """,
                    values: [link.id, group.id]
                )
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
        self.db.beginTransaction()
        do {
            try self.db.executeUpdate(
                """
                update tag
                set name = ?, color = ?
                where id = ?
                """,
                values: [tag.name, tag.colorHex, tag.id]
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
        self.db.beginTransaction()
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
    
    public func delete(_ link: Link) -> Bool {
        self.db.beginTransaction()
        do {
            try self.db.executeUpdate("delete from link where id = ?", values: [link.id])
            try self.db.executeUpdate("delete from category_link where link_id = ?", values: [link.id])
            try self.db.executeUpdate("delete from tag_link where link_id = ?", values: [link.id])
            self.db.commit()
            delegate?.databaseController(self, didDelete: link)
            return true
        } catch {
            os_log(.error, "encountered error while deleting link, error was: %@", error as CVarArg)
            self.db.rollback()
            return false
        }
    }
    
    public func delete(_ group: Group) -> Bool {
        self.db.beginTransaction()
        do {
            try self.db.executeUpdate("delete from category where id = ?", values: [group.id])
            try self.db.executeUpdate("delete from category_link where category_id = ?", values: [group.id])
            self.db.commit()
            delegate?.databaseController(self, didDelete: group)
            return true
        } catch {
            os_log(.error, "encountered error while deleting group, error was: %@", error as CVarArg)
            self.db.rollback()
            return false
        }
    }
    
    public func delete(_ tag: Tag) -> Bool {
        self.db.beginTransaction()
        do {
            try self.db.executeUpdate("delete from tag where id = ?", values: [tag.id])
            try self.db.executeUpdate("delete from tag_link where tag_id = ?", values: [tag.id])
            self.db.commit()
            delegate?.databaseController(self, didDelete: tag)
            return true
        } catch {
            os_log(.error, "encountered error while deleting tag, error was: %@", error as CVarArg)
            self.db.rollback()
            return false
        }
    }
}
