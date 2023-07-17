//
//  Account.swift
//  Ulry
//
//  Created by Matt on 06/11/2022.
//  Copyright © 2022 Mattia Righetti. All rights reserved.
//

#if os(iOS)
import UIKit
#endif

import os
import Links
import Foundation
import LinksDatabase
import LinksMetadata

public extension Notification.Name {
    static let UserDidAddLink = Notification.Name("UserDidAddLink")
    static let UserDidAddGroup = Notification.Name("UserDidAddGroup")
    static let UserDidAddTag = Notification.Name("UserDidAddTag")
    static let UserDidUpdateLink = Notification.Name("UserDidUpdateLink")
    static let UserDidUpdateGroup = Notification.Name("UserDidUpdateGroup")
    static let UserDidUpdateTag = Notification.Name("UserDidUpdateTag")
    static let UserDidDeleteLink = Notification.Name("UserDidDeleteLink")
    static let UserDidDeleteGroup = Notification.Name("UserDidDeleteGroup")
    static let UserDidDeleteTag = Notification.Name("UserDidDeleteTag")
    static let AccountIsFetching = Notification.Name("AccountIsFetching")
    static let AccountIsNotFetching = Notification.Name("AccountIsNotFetching")
}

public enum AccountType: Int, Codable {
    case local = 1
    case cloudkit = 2

    public var isDeveloperRestricted: Bool {
        self == .cloudkit
    }
}

public final class Account {
    public static let defaultLocalAccountName: String = {
        let defaultName: String
        #if os(macOS)
        defaultName = NSLocalizedString("On My Mac", comment: "Account name")
        #else
        if UIDevice.current.userInterfaceIdiom == .pad {
            defaultName = NSLocalizedString("On My iPad", comment: "Account name")
        } else {
            defaultName = NSLocalizedString("On My iPhone", comment: "Account name")
        }
        #endif

        return defaultName
    }()

    let dataFolder: String
    let database: LinksDatabase
    public var type: AccountType
    public var isActive: Bool
    public var accountID: String
    public let defaultName: String
    public let dataQueue: LinkDataQueue
    public let imageCache: CacheStorage

    public var account: Account? {
        return self
    }

    public var userAgentSignature: String = {
        var appVersion: String = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as! String
        var appBundleVersion: String = Bundle.main.infoDictionary?["CFBundleVersion"] as! String
        return "Ulry/\(appVersion)(\(appBundleVersion)"
    }()

    public init(dataFolder: String, type: AccountType, accountID: String, imageCache: CacheStorage) {
        switch type {
        case .local:
            defaultName = "Local"
        case .cloudkit:
            defaultName = "iCloud"
        }

        self.dataFolder = dataFolder
        self.type = type
        self.accountID = accountID

        self.isActive = true

        let databaseFilePath = (dataFolder as NSString).appendingPathComponent("ulry.sqlite")
        self.database = LinksDatabase(databaseFilePath: databaseFilePath)

        self.imageCache = imageCache

        self.dataQueue = LinkDataQueue(headerFields: [
            "User-Agent": userAgentSignature
        ])
    }

    // MARK: - Utils

    public func getDatabaseSize() -> String {
        let base = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
        let dbUrl = base.appendingPathComponent("ulry.sqlite")
        guard let fileAttributes = try? FileManager.default.attributesOfItem(atPath: dbUrl.path) else { return "N/A" }
        let fileSize = fileAttributes[.size] as! Int64

        let bcf = ByteCountFormatter()
        bcf.allowedUnits = [.useAll]
        bcf.countStyle = .file
        return bcf.string(fromByteCount: fileSize)
    }

    // MARK: - APIs

    public func fetchLinkIDs(in group: Group, order: OrderBy) throws -> [String] {
        return try database.fetchLinkIDs(in: group, order: order)
    }

    public func fetchLinkIDs(matching searchValue: String) throws -> [String] {
        return try database.fetchAllLinkIDs(matching: searchValue)
    }

    public func fetchLinkIDs(in tag: Tag, order: OrderBy) throws -> [String] {
        return try database.fetchLinkIDs(in: tag, order: order)
    }

    public func fetchAllLinkIDs(order: OrderBy) throws -> [String] {
        return try database.fetchAllLinkIDs(order: order)
    }

    public func fetchUnreadLinkIDs(order: OrderBy) throws -> [String] {
        return try database.fetchUnreadLinkIDs(order: order)
    }

    public func fetchStarredLinkIDs(order: OrderBy) throws -> [String] {
        return try database.fetchStarredLinkIDs(order: order)
    }

    public func fetchArchivedLinkIDs(order: OrderBy) throws -> [String] {
        return try database.fetchArchivedLinkIDs(order: order)
    }

    public func fetchLink(with id: String) throws -> Link? {
        return try database.fetchLink(with: id)
    }

    public func fetchTag(with id: String) throws -> Tag? {
        return try database.fetchTag(with: id)
    }

    public func fetchGroup(with id: String) throws -> Group? {
        return try database.fetchGroup(with: id)
    }

    public func fetchAllGroups() throws -> [Group] {
        return try database.fetchAllGroups()
    }

    public func fetchAllTags() throws -> [Tag] {
        return try database.fetchAllTags()
    }

    public func existsLink(with url: String) throws -> Bool {
        return try database.existsLink(with: url)
    }

    public func existsTag(with name: String) throws -> Bool {
        return try database.existsTag(name: name)
    }

    public func existsGroup(with name: String) throws -> Bool {
        return try database.existsGroup(name: name)
    }

    // MARK: Insert Link

    public func fetchAllTags() async throws -> [Tag] {
        return try await database.fetchAllTags()
    }

    public func fetchAllGroups() async throws -> [Group] {
        return try await database.fetchAllGroups()
    }

    public func fetchAllLinkIDs(order: OrderBy) async throws -> [String] {
        return try await database.fetchAllLinkIDsAsync(order: order)
    }

    // MARK: - Stats

    public func fetchStats() throws -> [DbStat] {
        return try database.fetchStats()
    }

    public func fetchLinksAddedInLastSevenDays() throws -> [(String, Int)] {
        return try database.fetchLinksAddedInLastSevenDays()
    }

    // MARK: - General Async

    @MainActor
    public func fetchBlock(_ f: (() async -> Void)) async {
        NotificationCenter.default.post(name: .AccountIsFetching, object: self, userInfo: nil)
        await f()
        NotificationCenter.default.post(name: .AccountIsNotFetching, object: self, userInfo: nil)
    }

    @MainActor
    public func insertBatch(links: [Link]) async {
        await fetchBlock {
            guard let links = try? await dataQueue.process(links) else {
                fatalError("something went wrong during insertBatch")
            }

            for link in links {
                do {
                    try await database.insertAsync(link: link)
                    NotificationCenter.default.post(name: .UserDidAddLink, object: self, userInfo: ["link": link, "toRemoveFromCache": link.url])
                } catch {
                    os_log(.error, "encountered error while trying to insert link in database asynchronously")
                }
            }

            try? await dataQueue.fetchImages(links)
                .filter({ $0.1 != nil })
                .forEach { imageCache.storeImageData($1!, with: $0.id) }
        }
    }

    @MainActor
    public func insertWithNoProcessing(links: [Link]) async {
        for link in links {
            do {
                try await database.insertAsync(link: link)
                NotificationCenter.default.post(name: .UserDidAddLink, object: self, userInfo: ["link": link])
            } catch {
                os_log(.error, "encountered error while trying to insert link in database asynchronously")
            }
        }

        try? await dataQueue.fetchImages(links)
            .filter({ $0.1 != nil })
            .forEach { imageCache.storeImageData($1!, with: $0.id) }
    }

    @MainActor
    public func insert(link: Link) async {
        let link = await dataQueue.process(link)
        do {
            try await database.insertAsync(link: link)
            NotificationCenter.default.post(name: .UserDidAddLink, object: self, userInfo: ["link": link])
        } catch {
            os_log(.error, "Encountered error while inserting link async")
        }

        if let data = await dataQueue.imageWorker(link) {
            imageCache.storeImageData(data, with: link.id)
        }
    }

    @MainActor
    public func reload(_ link: Link) async {
        let link = await dataQueue.process(link)
        do {
            try await database.updateAsync(link: link)
            NotificationCenter.default.post(name: .UserDidUpdateLink, object: self, userInfo: ["link": link])
        } catch {
            os_log(.error, "Encountered error while updating link async")
        }

        if let data = await dataQueue.imageWorker(link) {
            imageCache.storeImageData(data, with: link.id)
        }
    }

    @MainActor
    public func insert(tag: Tag) async {
        do {
            try await database.insertAsync(tag: tag)
            NotificationCenter.default.post(name: .UserDidAddTag, object: self, userInfo: ["tag": tag])
        } catch {
            os_log(.error, "Encountered error while inserting tag async")
        }
    }

    @MainActor
    public func insert(group: Group) async {
        do {
            try await database.insertAsync(group: group)
            NotificationCenter.default.post(name: .UserDidAddGroup, object: self, userInfo: ["group": group])
        } catch {
            os_log(.error, "Encountered error while inserting group async")
        }
    }

    @MainActor
    public func update(group: Group) async {
        do {
            try await database.updateAsync(group: group)
            NotificationCenter.default.post(name: .UserDidUpdateGroup, object: self, userInfo: ["group": group])
        } catch {
            os_log(.error, "Encountered error while updating group async")
        }
    }

    @MainActor
    public func update(tag: Tag) async {
        do {
            try await database.updateAsync(tag: tag)
            NotificationCenter.default.post(name: .UserDidUpdateTag, object: self, userInfo: ["tag": tag])
        } catch {
            os_log(.error, "Encountered error while updating tag async")
        }
    }

    @MainActor
    public func update(link: Link) async {
        do {
            try await database.updateAsync(link: link)
            NotificationCenter.default.post(name: .UserDidUpdateLink, object: self, userInfo: ["link": link])
        } catch {
            os_log(.error, "Encountered error while updating link async")
        }
    }

    @MainActor
    public func delete(link: Link) async {
        do {
            try await database.deleteAsync(link: link)
            try imageCache.deleteImageData(for: link)
            NotificationCenter.default.post(name: .UserDidDeleteLink, object: self, userInfo: ["link": link])
        } catch {
            os_log(.error, "Encountered error while deleting link async")
        }
    }

    @MainActor
    public func delete(tag: Tag) async {
        do {
            try await database.deleteAsync(tag: tag)
            NotificationCenter.default.post(name: .UserDidDeleteTag, object: self, userInfo: ["tag": tag])
        } catch {
            os_log(.error, "Encountered error while deleting tag async")
        }
    }

    @MainActor
    public func delete(group: Group) async {
        do {
            try await database.deleteAsync(group: group)
            NotificationCenter.default.post(name: .UserDidDeleteGroup, object: self, userInfo: ["group": group])
        } catch {
            os_log(.error, "Encountered error while deleting group async")
        }
    }
}

public protocol BaseError: Error {
    var title: String { get }
    var message: String { get }
}

extension Account {
    public enum ImportDataError: BaseError {
        case failedToFetchCurrentData
        case failedToAccessImortFile

        public var title: String {
            switch self {
            default: return "Error"
            }
        }

        public var message: String {
            switch self {
            case .failedToAccessImortFile:
                return "There was an error while trying to read import file, you might want to signal this to the developer."
            case .failedToFetchCurrentData:
                return "There was an error while fetching local data, you might want to signal this to the developer."
            }
        }
    }

    /// Exports all links, tags and groups to JSON and writes it to a temporary file with the name `ulry_backup`
    ///
    /// - returns: optional value of the URL of the file where data was written to
    public func exportToBinary() throws -> Data? {
        var links = try database.fetchAllLinkIDs(order: .newest).map { try? database.fetchLink(with: $0) }
        let archivedLinks = try database.fetchArchivedLinkIDs(order: .newest).map { try? database.fetchLink(with: $0) }
        links.append(contentsOf: archivedLinks)
        return try? JSONEncoder().encode(links)
    }

    public typealias ImportDataCount = (groups: Int, tags: Int, links: Int)

    /// Imports all links, tags and groups from a file passed as function's argument
    public func importFromBinary(_ fileUrl: URL) async throws -> Result<ImportDataCount, ImportDataError> {
        guard
            let currTags = try? await account?.fetchAllTags().map({ $0.id }).reduce(into: Set(), { $0?.insert($1) }),
            let currGroups = try? await account?.fetchAllGroups().map({ $0.id }).reduce(into: Set(), { $0?.insert($1) }),
            let currLinksIDs = try? await account?.fetchAllLinkIDs(order: .newest).reduce(into: Set(), { $0?.insert($1) })
        else { return .failure(.failedToFetchCurrentData) }

        os_log(.debug, "Currently stored groups: \(currGroups.count)")
        os_log(.debug, "Currently stored tags: \(currTags.count)")

        var links = [Link]()
        if fileUrl.startAccessingSecurityScopedResource() {
            let data = try Data(contentsOf: fileUrl)
            links = try JSONDecoder().decode([Link].self, from: data)
        } else {
            return .failure(.failedToAccessImortFile)
        }
        fileUrl.stopAccessingSecurityScopedResource()

        let tags = links
            .compactMap { $0.tags }
            .reduce(Set()) { partialResult, s in
                partialResult.union(s)
            }
            .filter { !currTags.contains($0.id) }

        let groups = links
            .compactMap { $0.group }
            .filter { !currGroups.contains($0.id) }
            .reduce(into: Set(), { res, g in
                res.insert(g)
            })

        for tag in tags {
            await account?.insert(tag: tag)
        }

        for group in groups {
            await account?.insert(group: group)
        }

        links = links.filter { !currLinksIDs.contains($0.id.uuidString) }
        if links.count > 0 {
            await account?.insertWithNoProcessing(links: links)
        }

        return .success((groups.count, tags.count, links.count))
    }
}
