//
//  LinksDatabase.swift
//  Ulry
//
//  Created by Matt on 06/11/2022.
//  Copyright © 2022 Mattia Righetti. All rights reserved.
//

import os
import Links
import Foundation

public final class LinksDatabase {
    private let queue: DatabaseQueue
    private let linksTable: LinksTable
    private let migrationsTable: MigrationsTable

    public init(databaseFilePath: String) {
        let queue = DatabaseQueue(databasePath: databaseFilePath)
        self.queue = queue

        try! queue.runCreateStatements(LinksDatabase.tableCreationStatements)

        self.migrationsTable = MigrationsTable(name: "migrations", queue: queue)
        self.linksTable = LinksTable(name: "link", queue: queue)
    }

    // MARK: - APIs

    // MARK: Links in Group

    public func fetchLinkIDs(in group: Group, order: OrderBy) throws -> [String] {
        return try linksTable.fetchLinkIDs(in: group, order: order)
    }

    public func fetchLinkIDsAsync(in group: Group, order: OrderBy) async throws -> [String] {
        return try await linksTable.fetchLinkIDsAsync(in: group, order: order)
    }

    // MARK: Links in Tag

    public func fetchLinkIDs(in tag: Tag, order: OrderBy) throws -> [String] {
        return try linksTable.fetchLinkIDs(in: tag, order: order)
    }

    public func fetchLinkIDsAsync(in tag: Tag, order: OrderBy) async throws -> [String] {
        return try await linksTable.fetchLinkIDsAsync(in: tag, order: order)
    }

    // MARK: Links Unread

    public func fetchUnreadLinkIDs(order: OrderBy) throws -> [String] {
        return try linksTable.fetchUnreadLinkIDs(order: order)
    }

    public func fetchUnreadLinkIDsAsync(order: OrderBy) async throws -> [String] {
        return try await linksTable.fetchUnreadLinkIDsAsync(order: order)
    }

    // MARK: Links Starred

    public func fetchStarredLinkIDs(order: OrderBy) throws -> [String] {
        return try linksTable.fetchStarredLinkIDs(order: order)
    }

    public func fetchStarredLinkIDsAsync(order: OrderBy) async throws -> [String] {
        return try await linksTable.fetchStarredLinkIDsAsync(order: order)
    }

    // MARK: Links Archived
    public func fetchArchivedLinkIDs(order: OrderBy) throws -> [String] {
        return try linksTable.fetchArchivedLinkIDs(order: order)
    }

    public func fetchArchivedLinkIDsAsync(order: OrderBy) async throws -> [String] {
        return try await linksTable.fetchArchivedLinkIDsAsync(order: order)
    }

    // MARK: All Links

    public func fetchAllLinkIDs(order: OrderBy) throws -> [String] {
        return try linksTable.fetchAllLinkIDs(order: order)
    }

    public func fetchAllLinkIDsAsync(order: OrderBy) async throws -> [String] {
        return try await linksTable.fetchAllLinkIDsAsync(order: order)
    }

    /// Returns link with specified URL, which is a unique field in database
    public func fetchLink(withUrl url: String) throws -> Link? {
        return try linksTable.fetchLink(withUrl: url)
    }

    /// Returns link with specified UUID
    public func fetchLink(with id: String) throws -> Link? {
        return try linksTable.fetchSingleLink(with: id)
    }

    public func fetchAllLinkIDs(matching value: String) throws -> [String] {
        return try linksTable.fetchAllLinkIDs(matching: value)
    }

    /// Returns group with a specified UUID
    public func fetchGroup(with id: String) throws -> Group? {
        return try linksTable.fetchSingleGroup(with: id)
    }

    /// Returns all groups in database
    public func fetchAllGroups() throws -> [Group] {
        return try linksTable.fetchAllGroups()
    }

    public func fetchAllGroups() async throws -> [Group] {
        return try await linksTable.fetchAllGroups()
    }

    /// Returns tag with specified UUID
    public func fetchTag(with id: String) throws -> Tag? {
        return try linksTable.fetchSingleTag(with: id)
    }

    /// Returns all tags in database
    public func fetchAllTags() throws -> [Tag] {
        return try linksTable.fetchAllTags()
    }

    public func fetchAllTags() async throws -> [Tag] {
        return try await linksTable.fetchAllTags()
    }

    /// Returns bool indicating wether a link with a
    /// give url is present or not in database.
    ///
    /// This method is useful to check if a url is unique in database
    /// before inserting antoher link to the database.
    public func existsLink(with url: String) throws -> Bool {
        return try linksTable.existsLink(with: url)
    }

    public func existsTag(name: String) throws -> Bool {
        return try linksTable.existsTag(name: name)
    }

    public func existsGroup(name: String) throws -> Bool {
        return try linksTable.existsGroup(name: name)
    }

    // MARK: Update Tag

    /// Updates tag with new data.
    public func update(tag: Tag) throws {
        try linksTable.update(tag: tag)
    }

    public func updateAsync(tag: Tag) async throws {
        return try await linksTable.updateAsync(tag: tag)
    }

    // MARK: Update Link

    public func update(link: Link) throws {
        try linksTable.update(link: link)
    }

    public func updateAsync(link: Link) async throws {
        return try await linksTable.updateAsync(link: link)
    }

    // MARK: Update Group

    public func update(group: Group) throws {
        try linksTable.update(group: group)
    }

    public func updateAsync(group: Group) async throws {
        return try await linksTable.updateAsync(group: group)
    }

    // MARK: Delete Tag

    public func delete(tag: Tag) throws {
        try linksTable.deleteTag(with: tag.id.uuidString)
    }

    public func deleteAsync(tag: Tag) async throws {
        return try await linksTable.deleteTagAsync(with: tag.id.uuidString)
    }

    // MARK: Delete Link

    public func delete(link: Link) throws {
        try linksTable.deleteLink(with: link.id.uuidString)
    }

    public func deleteAsync(link: Link) async throws {
        return try await linksTable.deleteLinkAsync(with: link.id.uuidString)
    }

    // MARK: Delete Group

    public func delete(group: Group) throws {
        try linksTable.deleteGroup(with: group.id.uuidString)
    }

    public func deleteAsync(group: Group) async throws {
        return try await linksTable.deleteGroupAsync(with: group.id.uuidString)
    }

    // MARK: Insert Link

    public func insert(link: Link) throws {
        try linksTable.insert(link: link)
    }

    public func insertAsync(link: Link) async throws {
        return try await linksTable.insertAsync(link: link)
    }

    // MARK: Insert Group

    public func insert(group: Group) throws {
        try linksTable.insert(group: group)
    }

    public func insertAsync(group: Group) async throws {
        return try await linksTable.insertAsync(group: group)
    }

    // MARK: Insert Tag

    public func insert(tag: Tag) throws {
        try linksTable.insert(tag: tag)
    }

    public func insertAsync(tag: Tag) async throws {
        return try await linksTable.insertAsync(tag: tag)
    }

    public func fetchStats() throws -> [DbStat] {
        return try linksTable.fetchStats()
    }

    public func fetchLinksAddedInLastSevenDays() throws -> [(String, Int)] {
        return try linksTable.fetchLinksAddedInLastSevenDays()
    }
}

private extension LinksDatabase {
    static let tableCreationStatements = """
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
}
