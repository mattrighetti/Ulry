import Foundation
import Darwin
import os

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

    var canSaveMoreLinks: Bool {
        pendingLinks.count < 15
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
        do {
            return try withQueue { links in
                guard links.count < 15 else { return false }
                links.append(ExtensionsAddLinkRequests(url: urlString, note: note, tagIds: tagIds, groupId: groupId))
                return true
            }
        } catch {
            os_log(.error, "Could not save extension request: %{public}@", String(describing: error))
            return false
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
                    if let index = remaining.firstIndex(of: request) {
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
        if exists {
            links = try JSONDecoder().decode([ExtensionsAddLinkRequests].self, from: Data(contentsOf: queueURL))
        } else {
            // Refresh the legacy suite once, then use the file as the source of truth.
            defaults?.synchronize()
            links = try defaults?.data(forKey: Self.legacyKey).map {
                try JSONDecoder().decode([ExtensionsAddLinkRequests].self, from: $0)
            } ?? []
        }
        let original = links
        let result = operation(&links)
        if !exists || links != original {
            try JSONEncoder().encode(links).write(to: queueURL, options: .atomic)
        }
        if !exists {
            defaults?.removeObject(forKey: Self.legacyKey)
            defaults?.synchronize()
        }
        return result
    }
}
