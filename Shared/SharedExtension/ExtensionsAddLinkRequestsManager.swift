//
//  LinkAddRequestFile.swift
//  Ulry
//
//  Created by Matt on 27/11/2022.
//  Copyright © 2022 Mattia Righetti. All rights reserved.
//

import Foundation

final class ExtensionsAddLinkRequestsManager: NSObject, Logging {

    private static var filePathUrl: URL = {
        URL.storeURL(for: "group.com.mattrighetti.Ulry", filename: "external_links.plist")
    }()

    var canSaveMoreLinks: Bool {
        externalCache.count < 15
    }

    override init() {
        super.init()
        NotificationCenter.default.addObserver(self, selector: #selector(remove(_:)), name: NSNotification.Name("UserDidAddLink"), object: nil)
    }

    @objc func remove(_ notification: Notification) {
        guard let url = notification.userInfo?["toRemoveFromCache"] as? String else { return }
        externalCache.removeValue(forKey: url)
    }

    lazy var externalCache: [String:ExtensionsAddLinkRequests] = {
        getCache()
    }()

    func getCache() -> [String:ExtensionsAddLinkRequests] {
        let decoder = PropertyListDecoder()
        var cache = [String:ExtensionsAddLinkRequests]()
        if let data = try? Data(contentsOf: Self.filePathUrl),
           let requests = try? decoder.decode([ExtensionsAddLinkRequests].self, from: data) {
            for req in requests {
                cache[req.url] = req
            }
        }
        return cache
    }

    func dropCache() {
        externalCache = [String:ExtensionsAddLinkRequests]()
    }

    func persistCache() {
        let encoder = PropertyListEncoder()
        encoder.outputFormat = .binary

        coordinateFileWrite { url in
            do {
                let data = try encoder.encode(externalCache)
                try data.write(to: url)
            } catch {
                logger.error("Save to disk failed: \(error.localizedDescription, privacy: .public)")
            }
        }
    }

    /// Coordinates file access
    private func coordinateFileWrite(run accessor: (URL) throws -> Void) {
        let errorPointer: NSErrorPointer = nil
        let fileCoordinator = NSFileCoordinator()
        let fileUrl = ExtensionsAddLinkRequestsManager.filePathUrl

        fileCoordinator.coordinate(writingItemAt: fileUrl, options: [.forMerging], error: errorPointer, byAccessor: { url in
            do {
                try accessor(url)
            } catch {
                logger.error("Save to disk failed: \(error.localizedDescription, privacy: .public)")
            }
        })

        if let error = errorPointer?.pointee {
            logger.error("Save to disk coordination failed: \(error.localizedDescription, privacy: .public)")
        }
    }

    /// Stores given `urlString` and `note` to external file
    func add(_ urlString: String, note: String?) {
        logger.info("saving \(urlString) with note \(note ?? "")")
        let decoder = PropertyListDecoder()
        let encoder = PropertyListEncoder()
        encoder.outputFormat = .binary

        coordinateFileWrite { url in
            var requests: [ExtensionsAddLinkRequests]
            if
                let fileData = try? Data(contentsOf: url),
                let decodedRequests = try? decoder.decode([ExtensionsAddLinkRequests].self, from: fileData)
            {
                requests = decodedRequests
            } else {
                requests = [ExtensionsAddLinkRequests]()
            }

            requests.append(ExtensionsAddLinkRequests(url: urlString, note: note))

            let data = try encoder.encode(requests)
            try data.write(to: url)
        }
    }
}
