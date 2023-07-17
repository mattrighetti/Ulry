//
//  File.swift
//  
//
//  Created by Matt on 15/12/2022.
//  Copyright © 2022 Mattia Righetti. All rights reserved.
//

import FMDB
import Links
import Foundation

// MARK: - Mapper

func mapResultToArray<T>(_ resultSet: FMResultSet, _ completion: (_ resultSet: FMResultSet) -> T?) -> [T] {
    var objects = [T]()
    while resultSet.next() {
        if let obj = completion(resultSet) {
            objects.append(obj)
        }
    }
    return objects
}

// MARK: - SQL

/// Fetches all `UUID`s of all the links in the database
func sql_fetchLinkIDs(whereClause: String? = nil, orderBy: (String, String)? = nil, _ database: FMDatabase) -> [String] {
    let sql = _sql_select("id", from: "link", where: whereClause, orderBy: orderBy)
    guard let resultSet = database.executeQuery(sql, withArgumentsIn: []) else {
        return [String]()
    }
    return mapResultToArray(resultSet, { $0.string(forColumn: "id") })
}

/// Fetches all the links in database
func sql_fetchLinks(whereClause: String? = nil, orderBy: (String, String)? = nil, _ database: FMDatabase) -> [Link] {
    let sql = _sql_select("*", from: "link", where: whereClause, orderBy: orderBy)
    guard let resultSet = database.executeQuery(sql, withArgumentsIn: []) else {
        return [Link]()
    }
    return mapResultToArray(resultSet, { Link(from: $0) })
}

/// Fetches link IDs with a specified tag that are not archived
func sql_fetchLinkIDsInTag(_ tag: Tag, orderBy: (String,String), _ database: FMDatabase) -> [String] {
    let whereClause = "id in (select tg.link_id from tag_link tg inner join link l on l.id = tg.link_id where tag_id = ?) and archived = false"
    let sql = _sql_select("id", from: "link", where: whereClause, orderBy: orderBy)
    guard let resultSet = database.executeQuery(sql, withArgumentsIn: [tag.id]) else {
        return [String]()
    }
    return mapResultToArray(resultSet, { $0.string(forColumn: "id") })
}

/// Fetches links with a specified tag that are not archived
func sql_fetchLinksInTag(_ tag: Tag, orderBy: (String,String), _ database: FMDatabase) -> [Link] {
    let whereClause = "id in (select tg.link_id from tag_link tg inner join link l on l.id = tg.link_id where tag_id = ?) and archived = false"
    let sql = _sql_select("*", from: "link", where: whereClause, orderBy: orderBy)
    guard let resultSet = database.executeQuery(sql, withArgumentsIn: [tag.id]) else {
        return [Link]()
    }
    return mapResultToArray(resultSet, { Link(from: $0) })
}

/// Fetches link IDs in  a specified group that are not archived
func sql_fetchLinkIDsInGroup(_ group: Group, orderBy: (String,String), _ database: FMDatabase) -> [String] {
    let sql = _sql_select("id", from: "link", where: "id in (select link_id from category_link where category_id = ?) and archived = false", orderBy: orderBy)
    guard let resultSet = database.executeQuery(sql, withArgumentsIn: [group.id]) else {
        return [String]()
    }
    return mapResultToArray(resultSet, { $0.string(forColumn: "id") })
}

/// Fetches links in a specified group that are not archived
func sql_fetchLinksInGroup(_ group: Group, orderBy: (String,String), _ database: FMDatabase) -> [Link] {
    let sql = _sql_select("*", from: "link", where: "id in (select link_id from category_link where category_id = ?) and archived = false", orderBy: orderBy)
    guard let resultSet = database.executeQuery(sql, withArgumentsIn: [group.id]) else {
        return [Link]()
    }
    return mapResultToArray(resultSet, { Link(from: $0) })
}

func sql_fetchSingleLinkID(whereClause: String? = nil, orderBy: (String, String)? = nil, _ database: FMDatabase) -> String {
    let links = sql_fetchLinkIDs(whereClause: whereClause, orderBy: orderBy, database)
    if links.count != 1 {
        assertionFailure("expected single link but found \(links.count)")
    }
    return links.first!
}

func sql_fetchOptionalSingleLink(whereClause: String, _ database: FMDatabase) -> Link? {
    let link = sql_fetchLinks(whereClause: whereClause, database)
    assert(link.count <= 1)
    return link.first
}

func sql_fetchSingleLink(whereClause: String, orderBy: (String, String)? = nil, _ database: FMDatabase) -> Link {
    let links = sql_fetchLinks(whereClause: whereClause, orderBy: orderBy, database)
    guard links.count == 1, let link = links.first else {
        fatalError("expected single link but found \(links.count)")
    }

    link.group = sql_fetchGroupOfLink(withUuid: link.id.uuidString, database)

    let tagSet = Set(sql_fetchTagsOfLink(withUuid: link.id.uuidString, database))
    if tagSet.count > 0 {
        link.tags = tagSet
    }

    return links.first!
}

// MARK: - Exists

func sql_existsLink(url: String, _ database: FMDatabase) -> Bool {
    return sql_fetchLinks(whereClause: "url = '\(url)'", database).count > 0
}

func sql_existsTag(name: String, _ database: FMDatabase) -> Bool {
    return sql_fetchAllTags(whereClause: "name = '\(name)'", database).count > 0
}

func sql_existsGroup(name: String, _ database: FMDatabase) -> Bool {
    return sql_fetchAllGroups(whereClause: "name = '\(name)'", database).count > 0
}

// MARK: Group

func sql_fetchAllGroups(whereClause: String? = nil, orderBy: (String, String)? = ("name", "asc"), _ database: FMDatabase) -> [Group] {
    let sql = _sql_select("*", from: "category", where: whereClause, orderBy: orderBy)
    guard let resultSet = database.executeQuery(sql, withArgumentsIn: []) else {
        return [Group]()
    }
    return mapResultToArray(resultSet, { Group(from: $0) })
}

func sql_fetchSingleGroup(whereClause: String, _ database: FMDatabase) -> Group {
    let groups = sql_fetchAllGroups(whereClause: whereClause, database)
    if groups.count != 1 {
        assertionFailure("expected single group but found \(groups.count)")
    }
    return groups.first!
}

// MARK: Tags

func sql_fetchAllTags(whereClause: String? = nil, orderBy: (String, String)? = ("name", "asc"), _ database: FMDatabase) -> [Tag] {
    let sql = _sql_select("*", from: "tag", where: whereClause, orderBy: orderBy)
    guard let resultSet = database.executeQuery(sql, withArgumentsIn: []) else {
        return [Tag]()
    }
    return mapResultToArray(resultSet, { Tag(from: $0) })
}

func sql_fetchSingleTag(whereClause: String, _ database: FMDatabase) -> Tag {
    let tags = sql_fetchAllTags(whereClause: whereClause, database)
    if tags.count != 1 {
        assertionFailure("expected single tag but found \(tags.count)")
    }
    return tags.first!
}

func sql_fetchGroupOfLink(withUuid uuid: String, _ database: FMDatabase) -> Group? {
    let sql = _sql_select("*", from: "category", where: "id in (select category_id from category_link where link_id = ?)", orderBy: nil)

    guard let resultSet = database.executeQuery(sql, withArgumentsIn: [uuid]) else { return nil }
    if resultSet.next() {
        let group = Group(from: resultSet)
        return group
    }

    return nil
}

func sql_fetchTagsOfLink(withUuid uuid: String, _ database: FMDatabase) -> [Tag] {
    let sql = _sql_select("*", from:"tag", where: "id in (select tag_id from tag_link where link_id = ?)", orderBy: nil)
    guard let resultSet = database.executeQuery(sql, withArgumentsIn: [uuid]) else { return [Tag]() }
    return mapResultToArray(resultSet, { Tag(from: $0) })
}

public enum DatabaseStat: String, Hashable {
    case countAll = "All"
    case countUnread = "Unread"
    case countStarred = "Starred"
    case countArchived = "Archived"
}

public typealias DbStat = (DatabaseStat, Int)

func sql_fetchStats(_ database: FMDatabase) -> [DbStat] {
    let sql_count_all = "select count(*) from link;"
    let sql_count_unread = "select count(*) from link where unread=1;"
    let sql_count_starred = "select count(*) from link where starred=1;"
    let sql_count_archived = "select count(*) from link where archived=1;"

    var stats = [DbStat]()
    if let res = database.executeQuery(sql_count_all, withArgumentsIn: []), res.next() {
        let dbStat = (DatabaseStat.countAll, Int(res.int(forColumnIndex: 0)))
        stats.append(dbStat)
    }

    if let res = database.executeQuery(sql_count_unread, withArgumentsIn: []), res.next() {
        let dbStat = (DatabaseStat.countUnread, Int(res.int(forColumnIndex: 0)))
        stats.append(dbStat)
    }

    if let res = database.executeQuery(sql_count_starred, withArgumentsIn: []), res.next() {
        let dbStat = (DatabaseStat.countStarred, Int(res.int(forColumnIndex: 0)))
        stats.append(dbStat)
    }

    if let res = database.executeQuery(sql_count_archived, withArgumentsIn: []), res.next() {
        let dbStat = (DatabaseStat.countArchived, Int(res.int(forColumnIndex: 0)))
        stats.append(dbStat)
    }
    
    return stats
}

func sql_fetchLinksAddedInLastSevenDays(_ database: FMDatabase) -> [(String, Int)] {
    let sql = "select count(*) as tot, date(created_at, 'unixepoch') as date from link group by date order by date desc limit 10;"
    guard let res = try? database.executeQuery(sql, values: []) else { return [(String, Int)]() }
    return mapResultToArray(res) {
        (
            $0.string(forColumn: "date")!,
            Int($0.int(forColumn: "tot"))
        )
    }
}


// MARK: Delete

/// Deletes single tag from database, along with all the 1-to-n relations with `tag_link`
func sql_deleteTag(id: String, _ database: FMDatabase) {
    database.executeUpdate(_sql_delete(from: "tag", where: "id = ?"), withArgumentsIn: [id])
}

/// Deletes single link with specific `UUID` from database, along with all the 1-to-n relationships
/// in `category_link` and `tag_link`
func sql_deleteLink(id: String, _ database: FMDatabase) {
    database.executeUpdate(_sql_delete(from: "link", where: "id = ?"), withArgumentsIn: [id])
}

/// Deletes single group with specific `UUID` from database, along with all the 1-to-n relationships
/// in `category_link`
func sql_deleteGroup(id: String, _ database: FMDatabase) {
    database.executeUpdate(_sql_delete(from: "category", where: "id = ?"), withArgumentsIn: [id])
}

// MARK: Update

func sql_update(_ link: Link, _ database: FMDatabase) {
    let sql = _sql_update("link", fields: ["url", "starred", "archived", "unread", "color", "updated_at", "note", "ogTitle", "ogImageUrl", "ogDescription"], where: "id = ?")
    database.executeUpdate(sql, withArgumentsIn: [
        link.url, link.starred, link.archived, link.unread, link.colorHex,
        Int32(Date.now.timeIntervalSince1970), link.note ?? NSNull(),
        link.ogTitle ?? NSNull(), link.ogImageUrl ?? NSNull(),
        link.ogDescription ?? NSNull(), link.id
    ])

    // Delete all tags entries, the only
    // source of truth is the current link
    database.executeUpdate(_sql_delete(from: "tag_link", where: "link_id = ?"), withArgumentsIn: [link.id])

    // Delete all groups entries, the only
    // source of truth is the current link
    database.executeUpdate(_sql_delete(from: "category_link", where: "link_id = ?"), withArgumentsIn: [link.id])

    link.tags?.forEach {
        database.executeUpdate(_sql_insert(into: "tag_link", fields: ["link_id", "tag_id"]), withArgumentsIn: [link.id, $0.id])
    }

    if let group = link.group {
        database.executeUpdate(_sql_insert(into: "category_link", fields: ["link_id", "category_id"]), withArgumentsIn: [link.id, group.id])
    }
}

/// Updated group with specified `UUID` in database with passed group
func sql_update(_ group: Group, _ database: FMDatabase) {
    database.executeUpdate(_sql_update("category", fields: ["name", "icon", "color"], where: "id = ?"), withArgumentsIn: [group.name, group.iconName, group.colorHex, group.id])
}

/// Updates tag with specified `UUID` in database with passed tag
func sql_update(_ tag: Tag, _ database: FMDatabase) {
    database.executeUpdate(_sql_update("tag", fields: ["name", "color"], where: "id = ?"), withArgumentsIn: [tag.name, tag.colorHex, tag.id])
}

func sql_fetchLinkIDs(matching value: String, _ database: FMDatabase) -> [String] {
    let searchString = sqliteSearchString(with: value)
    guard let resultSet = database.executeQuery("select id from search where search match ?;", withArgumentsIn: [searchString]) else {
        return [String]()
    }
    return mapResultToArray(resultSet, { $0.string(forColumn: "id") })
}

// MARK: Insert

/// Inserts link into database
///
/// Links have unique `UUID` and `url` in database
func sql_insert(_ link: Link, _ database: FMDatabase) {
    database.executeUpdate(
        _sql_insert(into: "link", fields: ["id", "url", "starred", "archived", "unread", "color", "created_at", "updated_at", "note", "ogTitle", "ogDescription", "ogImageUrl"]),
        withArgumentsIn: [
            link.id, link.url, link.starred, link.archived, link.unread,
            link.colorHex, link.createdAt, link.updatedAt,
            link.note ?? NSNull(), link.ogTitle ?? NSNull(),
            link.ogDescription ?? NSNull(), link.ogImageUrl ?? NSNull()
        ]
    )

    if let group = link.group {
        database.executeUpdate(
            _sql_insert(into: "category_link", fields: ["link_id", "category_id"]),
            withArgumentsIn: [link.id, group.id]
        )
    }

    link.tags?.forEach {
        database.executeUpdate(
            _sql_insert(into: "tag_link", fields: ["link_id", "tag_id"]),
            withArgumentsIn: [link.id, $0.id]
        )
    }
}

/// Inserts group into database
///
/// Groups have unique `UUID` and `name` in database
func sql_insert(_ group: Group, _ database: FMDatabase) {
    database.executeUpdate(
        _sql_insert(into: "category", fields: ["id", "name", "icon", "color"]),
        withArgumentsIn: [group.id, group.name, group.iconName, group.colorHex]
    )
}

/// Inserts tag into database
///
/// Tags have unique `UUID` and `name` in database
func sql_insert(_ tag: Tag, _ database: FMDatabase) {
    database.executeUpdate(
        _sql_insert(into: "tag", fields: ["id", "name", "color"]),
        withArgumentsIn: [tag.id, tag.name, tag.colorHex]
    )
}

// MARK: - Utils

func sqliteSearchString(with searchString: String) -> String {
    var s = ""
    searchString.enumerateSubstrings(in: searchString.startIndex..<searchString.endIndex, options: .byWords) { (word, range, enclosingRange, stop) in
        guard let word = word else {
            return
        }
        s += word
        if word != "AND" && word != "OR" {
            s += "*"
        }
        s += " "
    }
    return s
}
