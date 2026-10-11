import Foundation
import Darwin
import os

/// Validation is shared by the share sheet, Safari action, and Shortcuts.
enum SharedWebURL {
    static func parse(_ value: String) -> URL? {
        let trimmed = value.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.contains(where: { $0.isWhitespace }),
              let url = URL(string: trimmed),
              let scheme = url.scheme?.lowercased(),
              scheme == "http" || scheme == "https",
              let host = url.host, !host.isEmpty else { return nil }
        return url
    }

    static func fromJavaScriptItem(_ item: Any?) -> URL? {
        guard let dictionary = item as? NSDictionary,
              let results = dictionary[NSExtensionJavaScriptPreprocessingResultsKey] as? NSDictionary,
              let value = results["url"] as? String else { return nil }
        return parse(value)
    }
}

enum ExtensionSaveResult: Equatable {
    case saved, full, invalidURL, storageFailure
}

enum ExtensionQueueStatus: Equatable {
    case available, full, unavailable
}

/// The app and every extension share one queue and one cross-process lock.
final class ExtensionsAddLinkRequestsManager {
    private static let suite = "group.com.mattrighetti.Ulry"
    private static let legacyKey = "pendingLinks"

    private let defaults: UserDefaults?
    private let directory: URL?

    init(
        defaults: UserDefaults? = UserDefaults(suiteName: suite),
        directory: URL? = FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: suite)
    ) {
        self.defaults = defaults
        self.directory = directory
    }

    var canSaveMoreLinks: Bool { status == .available }

    var status: ExtensionQueueStatus {
        do { return try withQueue { $0.count < 15 ? .available : .full } }
        catch { return .unavailable }
    }

    var pendingLinks: [ExtensionsAddLinkRequests] {
        do {
            return try withQueue { $0 }
        } catch {
            os_log(.error, "Could not read extension queue: %{public}@", String(describing: error))
            return []
        }
    }

    @discardableResult
    func add(_ urlString: String, note: String?, tagIds: [String]? = nil, groupId: String? = nil) -> Bool {
        save(urlString, note: note, tagIds: tagIds, groupId: groupId) == .saved
    }

    func save(_ urlString: String, note: String?, tagIds: [String]? = nil, groupId: String? = nil) -> ExtensionSaveResult {
        guard let url = SharedWebURL.parse(urlString) else { return .invalidURL }
        do {
            return try withQueue { links in
                guard links.count < 15 else { return .full }
                links.append(ExtensionsAddLinkRequests(url: url.absoluteString, note: note, tagIds: tagIds, groupId: groupId))
                return .saved
            }
        } catch {
            os_log(.error, "Could not save extension request: %{public}@", String(describing: error))
            return .storageFailure
        }
    }

    func clearAll() {
        do {
            try withQueue { $0.removeAll() }
        } catch {
            os_log(.error, "Could not clear extension queue: %{public}@", String(describing: error))
        }
    }

    /// Acknowledge only saved requests, preserving requests added during import.
    func remove(_ requests: [ExtensionsAddLinkRequests]) {
        guard !requests.isEmpty else { return }
        do {
            try withQueue { remaining in
                for request in requests {
                    if let index = remaining.firstIndex(where: { $0.id == request.id }) {
                        remaining.remove(at: index)
                    }
                }
            }
        } catch {
            os_log(.error, "Could not acknowledge extension requests: %{public}@", String(describing: error))
        }
    }

    private func withQueue<T>(_ operation: (inout [ExtensionsAddLinkRequests]) -> T) throws -> T {
        guard let directory else { throw CocoaError(.fileNoSuchFile) }
        // Lock a separate file: atomic replacement changes the queue file's inode.
        let descriptor = open(directory.appendingPathComponent("pendingLinks.lock").path, O_CREAT | O_RDWR, S_IRUSR | S_IWUSR)
        guard descriptor >= 0 else { throw POSIXError(POSIXErrorCode(rawValue: errno) ?? .EIO) }
        defer { close(descriptor) }
        while flock(descriptor, LOCK_EX) != 0 {
            guard errno == EINTR else { throw POSIXError(POSIXErrorCode(rawValue: errno) ?? .EIO) }
        }
        defer { flock(descriptor, LOCK_UN) }

        let queueURL = directory.appendingPathComponent("pendingLinks.json")
        let exists = FileManager.default.fileExists(atPath: queueURL.path)
        var links: [ExtensionsAddLinkRequests]
        var needsMigration = false
        if exists {
            let data = try Data(contentsOf: queueURL)
            // Persist generated IDs before returning a legacy batch to the importer.
            let entries = try JSONSerialization.jsonObject(with: data) as? [[String: Any]]
            needsMigration = entries?.contains { $0["id"] == nil || $0["id"] is NSNull } == true
            links = try JSONDecoder().decode([ExtensionsAddLinkRequests].self, from: data)
        } else {
            // Refresh the legacy suite once, then use the file as the source of truth.
            defaults?.synchronize()
            links = try defaults?.data(forKey: Self.legacyKey).map {
                try JSONDecoder().decode([ExtensionsAddLinkRequests].self, from: $0)
            } ?? []
        }
        let original = links
        let result = operation(&links)
        if !exists || needsMigration || links != original {
            try JSONEncoder().encode(links).write(to: queueURL, options: .atomic)
        }
        if !exists {
            defaults?.removeObject(forKey: Self.legacyKey)
            defaults?.synchronize()
        }
        return result
    }
}
