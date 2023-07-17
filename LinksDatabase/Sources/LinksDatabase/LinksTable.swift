//
//  LinksTable.swift
//  Ulry
//
//  Created by Matt on 06/11/2022.
//  Copyright © 2022 Mattia Righetti. All rights reserved.
//

import Links
import FMDB

public typealias DbResultCompletionBlock<T> = (Result<T, DatabaseError>) -> Void

// MARK: - Table
final class LinksTable: DatabaseTable {
    let name: String
    private let queue: DatabaseQueue

    private var linksCache = [String: Link]()

    init(name: String, queue: DatabaseQueue) {
        self.name = name
        self.queue = queue
    }

    // MARK: - Fetch Link IDs
    func fetchLink(withUrl url: String) throws -> Link? {
        return try fetchSingleGeneric { sql_fetchOptionalSingleLink(whereClause: #"url = "\#(url)""#, $0) }
    }

    func fetchLinkIDs(in group: Group, order: OrderBy) throws -> [String] {
        return try fetchGenerics { sql_fetchLinkIDsInGroup(group, orderBy: order.orderByClause, $0) }
    }

    func fetchLinkIDsAsync(in group: Group, order: OrderBy) async throws -> [String] {
        return try await fetchGenericsAsync { sql_fetchLinkIDsInGroup(group, orderBy: order.orderByClause, $0) }
    }

    func fetchLinkIDs(in tag: Tag, order: OrderBy) throws -> [String] {
        return try fetchGenerics { sql_fetchLinkIDsInTag(tag, orderBy: order.orderByClause, $0) }
    }

    func fetchLinkIDsAsync(in tag: Tag, order: OrderBy) async throws -> [String] {
        return try await fetchGenericsAsync { sql_fetchLinkIDsInTag(tag, orderBy: order.orderByClause, $0) }
    }

    func fetchUnreadLinkIDs(order: OrderBy) throws -> [String] {
        return try fetchGenerics { sql_fetchLinkIDs(whereClause: "unread = true and archived = false", orderBy: order.orderByClause, $0) }
    }

    func fetchUnreadLinkIDsAsync(order: OrderBy) async throws -> [String] {
        return try await fetchGenericsAsync { sql_fetchLinkIDs(whereClause: "unread = true and archived = false", orderBy: order.orderByClause, $0) }
    }

    func fetchStarredLinkIDs(order: OrderBy) throws -> [String] {
        return try fetchGenerics { sql_fetchLinkIDs(whereClause: "starred = true and archived = false", orderBy: order.orderByClause, $0) }
    }

    func fetchStarredLinkIDsAsync(order: OrderBy) async throws -> [String] {
        return try await fetchGenericsAsync { sql_fetchLinkIDs(whereClause: "starred = true and archived = false", orderBy: order.orderByClause, $0) }
    }

    func fetchArchivedLinkIDs(order: OrderBy) throws -> [String] {
        return try fetchGenerics { sql_fetchLinkIDs(whereClause: "archived = true", orderBy: order.orderByClause, $0) }
    }

    func fetchArchivedLinkIDsAsync(order: OrderBy) async throws -> [String] {
        return try await fetchGenericsAsync { sql_fetchLinkIDs(whereClause: "archived = true", orderBy: order.orderByClause, $0) }
    }

    func fetchAllLinkIDs(order: OrderBy) throws -> [String] {
        return try fetchGenerics { sql_fetchLinkIDs(whereClause: "archived = false", orderBy: order.orderByClause, $0) }
    }

    func fetchAllLinkIDs(matching value: String) throws -> [String] {
        return try fetchGenerics { sql_fetchLinkIDs(matching: value, $0) }
    }

    func fetchAllLinkIDsAsync(order: OrderBy) async throws -> [String] {
        return try await fetchGenericsAsync { sql_fetchLinkIDs(orderBy: order.orderByClause, $0) }
    }

    // MARK: - Fetch Links

    func existsLink(with url: String) throws -> Bool {
        return try fetchSingleGeneric { sql_existsLink(url: url, $0) }!
    }

    func existsTag(name: String) throws -> Bool {
        return try fetchSingleGeneric { sql_existsTag(name: name, $0) }!
    }

    func existsGroup(name: String) throws -> Bool {
        return try fetchSingleGeneric { sql_existsGroup(name:name, $0) }!
    }

    func fetchLinks(in group: Group, order: OrderBy) throws -> [Link] {
        return try fetchGenerics { sql_fetchLinksInGroup(group, orderBy: order.orderByClause, $0) }
    }

    func fetchLinksAsync(in group: Group, order: OrderBy) async throws -> [Link] {
        return try await fetchGenericsAsync { sql_fetchLinksInGroup(group, orderBy: order.orderByClause, $0) }
    }

    func fetchLinks(in tag: Tag, order: OrderBy) throws -> [Link] {
        return try fetchGenerics { sql_fetchLinksInTag(tag, orderBy: order.orderByClause, $0) }
    }

    func fetchLinksAsync(in tag: Tag, order: OrderBy) async throws -> [Link] {
        return try await fetchGenericsAsync { sql_fetchLinksInTag(tag, orderBy: order.orderByClause, $0) }
    }

    func fetchUnreadLinks(order: OrderBy) throws -> [Link] {
        return try fetchGenerics { sql_fetchLinks(whereClause: "unread = true and archived = false", orderBy: order.orderByClause, $0) }
    }

    func fetchUnreadLinksAsync(order: OrderBy) async throws -> [Link] {
        return try await fetchGenericsAsync { sql_fetchLinks(whereClause: "unread = true and archived = false", orderBy: order.orderByClause, $0) }
    }

    func fetchStarredLinks(order: OrderBy) throws -> [Link] {
        return try fetchGenerics { sql_fetchLinks(whereClause: "starred = true and archived = false", orderBy: order.orderByClause, $0) }
    }

    func fetchStarredLinksAsync(order: OrderBy) async throws -> [Link] {
        return try await fetchGenericsAsync { sql_fetchLinks(whereClause: "starred = true and archived = false", orderBy: order.orderByClause, $0) }
    }

    func fetchAllLinks(order: OrderBy) throws -> [Link] {
        return try fetchGenerics { sql_fetchLinks(orderBy: order.orderByClause, $0) }
    }

    func fetchAllLinksAsync(order: OrderBy) async throws -> [Link] {
        return try await fetchGenericsAsync { sql_fetchLinks(orderBy: order.orderByClause, $0) }
    }

    func fetchAllLinksAsync(order: OrderBy, _ completion: @escaping DbResultCompletionBlock<[Link]>) {
        fetchGenericsAsync({ sql_fetchLinks(orderBy: order.orderByClause, $0) }, completion: completion)
    }

    func fetchSingleLink(with id: String) throws -> Link? {
        return try fetchSingleGeneric { sql_fetchSingleLink(whereClause: #"id = "\#(id)""#, $0) }
    }

    func fetchAllGroups() throws -> [Group] {
        return try fetchGenerics { sql_fetchAllGroups($0) }
    }

    func fetchAllGroups() async throws -> [Group] {
        return try await fetchGenericsAsync { sql_fetchAllGroups($0) }
    }

    func fetchSingleGroup(with id: String) throws -> Group? {
        return try fetchSingleGeneric { sql_fetchSingleGroup(whereClause: #"id = "\#(id)""#, $0) }
    }

    func fetchAllTags() throws -> [Tag] {
        return try fetchGenerics { sql_fetchAllTags($0) }
    }

    func fetchAllTags() async throws -> [Tag] {
        return try await fetchGenericsAsync { sql_fetchAllTags($0) }
    }

    func fetchSingleTag(with id: String) throws -> Tag? {
        return try fetchSingleGeneric { sql_fetchSingleTag(whereClause: #"id = "\#(id)""#, $0) }
    }

    func deleteTag(with id: String) throws {
        try execGeneric { sql_deleteTag(id: id, $0) }
    }

    func deleteTagAsync(with id: String) async throws {
        return try await execGenericAsync { sql_deleteTag(id: id, $0) }
    }

    func deleteLink(with id: String) throws {
        try execGeneric { sql_deleteLink(id: id, $0) }
    }

    func deleteLinkAsync(with id: String) async throws {
        return try await execGenericAsync { sql_deleteLink(id: id, $0) }
    }

    func deleteGroup(with id: String) throws {
        try execGeneric { sql_deleteGroup(id: id, $0) }
    }

    func deleteGroupAsync(with id: String) async throws {
        return try await execGenericAsync { sql_deleteGroup(id: id, $0) }
    }

    func update(group: Group) throws {
        try execGeneric { sql_update(group, $0) }
    }

    func updateAsync(group: Group) async throws {
        return try await execGenericAsync { sql_update(group, $0) }
    }

    func update(tag: Tag) throws {
        try execGeneric { sql_update(tag, $0) }
    }

    func updateAsync(tag: Tag) async throws {
        return try await execGenericAsync { sql_update(tag, $0) }
    }

    func update(link: Link) throws {
        try execGeneric { sql_update(link, $0) }
    }

    func updateAsync(link: Link) async throws {
        return try await execGenericAsync { sql_update(link, $0) }
    }

    func insert(link: Link) throws {
        try execGeneric { sql_insert(link, $0) }
    }

    func insertAsync(link: Link) async throws {
        return try await execGenericAsync { sql_insert(link, $0) }
    }

    func insert(group: Group) throws {
        try execGeneric { sql_insert(group, $0) }
    }

    func insertAsync(group: Group) async throws {
        return try await execGenericAsync { sql_insert(group, $0) }
    }

    func insert(tag: Tag) throws {
        try execGeneric { sql_insert(tag, $0) }
    }

    func insertAsync(tag: Tag) async throws {
        return try await execGenericAsync { sql_insert(tag, $0) }
    }

    func fetchStats() throws -> [DbStat] {
        return try fetchGenerics { sql_fetchStats($0) }
    }

    func fetchLinksAddedInLastSevenDays() throws -> [(String, Int)] {
        return try fetchGenerics { sql_fetchLinksAddedInLastSevenDays($0) }
    }

    // MARK: - Column

    func containsColumn(_ columnName: String, in database: FMDatabase) -> Bool {
        if let resultSet = database.executeQuery("select * from \(name) limit 1", withArgumentsIn: []) {
            let columnMap = resultSet.columnNameToIndexMap
            if let _ = columnMap[columnName.lowercased()] {
                return true
            }
        }
        return false
    }

}

extension LinksTable {
    // MARK: - Generics
    @available(*, renamed: "fetchGenericsAsync(_:)")
    func fetchGenericsAsync<T>(_ fetchMethod: @escaping ((FMDatabase) -> [T]), completion: @escaping ((Result<[T], DatabaseError>) -> Void)) {
        queue.runInDatabase { databaseResult in
            switch databaseResult {
            case .success(let database):
                let Ts = fetchMethod(database)
                DispatchQueue.main.async {
                    completion(.success(Ts))
                }
            case .failure(let databaseError):
                DispatchQueue.main.async {
                    completion(.failure(databaseError))
                }
            }
        }
    }

    @MainActor
    func fetchGenericsAsync<T>(_ fetchMethod: @escaping ((FMDatabase) -> [T])) async throws -> [T] {
        return try await withCheckedThrowingContinuation { continuation in
            fetchGenericsAsync(fetchMethod) { result in
                continuation.resume(with: result)
            }
        }
    }


    func fetchGenerics<T>(_ fetchMethod: @escaping ((FMDatabase) -> [T])) throws -> [T] {
        var Ts = [T]()
        var error: DatabaseError? = nil

        queue.runInDatabaseSync { databaseResult in
            if case .failure(let databaseError) = databaseResult {
                error = databaseError
            }

            if case .success(let database) = databaseResult {
                Ts = fetchMethod(database)
            }
        }

        if let error = error {
            throw(error)
        }

        return Ts
    }

    func fetchSingleGeneric<T>(_ fetchMethod: @escaping ((FMDatabase) -> T?)) throws -> T? {
        var t: T? = nil
        var error: DatabaseError? = nil

        queue.runInDatabaseSync { databaseResult in
            if case .failure(let databaseError) = databaseResult {
                error = databaseError
            }

            if case .success(let database) = databaseResult {
                t = fetchMethod(database)
            }
        }

        if let error = error {
            throw(error)
        }

        return t
    }

    @available(*, renamed: "fetchSingleGenericsAsync(_:)")
    func fetchSingleGenericsAsync<T>(_ fetchMethod: @escaping ((FMDatabase) -> T?), completion: @escaping ((Result<T?, DatabaseError>) -> Void)) {
        queue.runInDatabase { databaseResult in
            switch databaseResult {
            case .success(let database):
                let t = fetchMethod(database)
                DispatchQueue.main.async {
                    completion(.success(t))
                }
            case .failure(let databaseError):
                DispatchQueue.main.async {
                    completion(.failure(databaseError))
                }
            }
        }
    }

    @MainActor
    func fetchSingleGenericsAsync<T>(_ fetchMethod: @escaping ((FMDatabase) -> T?)) async throws -> T? {
        return try await withCheckedThrowingContinuation { continuation in
            fetchSingleGenericsAsync(fetchMethod) { result in
                continuation.resume(with: result)
            }
        }
    }

    func execGeneric(_ execMethod: @escaping ((FMDatabase) -> Void)) throws {
        var error: DatabaseError? =  nil
        queue.runInDatabaseSync { databaseResult in
            if case .failure(let databaseError) = databaseResult {
                error = databaseError
            }

            if case .success(let database) = databaseResult {
                execMethod(database)
            }
        }

        if let error = error {
            throw(error)
        }
    }

    @available(*, renamed: "execGenericAsync(_:)")
    func execGenericAsync(_ execMethod: @escaping ((FMDatabase) -> Void), completion: @escaping DbResultCompletionBlock<()>) {
        queue.runInDatabase { databaseResult in
            switch databaseResult {
            case .success(let database):
                execMethod(database)
                DispatchQueue.main.async {
                    completion(.success(()))
                }
            case .failure(let databaseError):
                DispatchQueue.main.async {
                    completion(.failure(databaseError))
                }
            }
        }
    }

    @MainActor
    func execGenericAsync(_ execMethod: @escaping ((FMDatabase) -> Void)) async throws {
        return try await withCheckedThrowingContinuation { continuation in
            execGenericAsync(execMethod) { result in
                continuation.resume(with: result)
            }
        }
    }

}
