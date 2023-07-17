//
//  File.swift
//  
//
//  Created by Matt on 09/11/2022.
//  Copyright © 2022 Mattia Righetti. All rights reserved.
//

import os
import Links
import Combine
import Foundation

public protocol CacheStorage {
    func getImageData(filename: String) -> Data?
    func storeImageData(_ data: Data, for link: Link)
    func storeImageData(_ data: Data, filenameId: String)
    func storeImageData(_ data: Data, with id: UUID)
    func deleteImageData(for link: Link) throws
    func deleteImageData(with id: UUID) throws
}

public final class LinkDataQueue {

    private let requestHeaderFields: [String: String]

    public enum QueueError: Error {
        case urlError
        case serverError
        case unknownError
    }

    public init(headerFields: [String:String]) {
        self.requestHeaderFields = headerFields
    }

    public func process(_ link: Link) async -> Link {
        guard let url = URL(string: link.url) else {
            os_log(.error, "error creating url for \(link.url)")
            return link
        }

        var req = URLRequest(url: url)
        req.cachePolicy = .reloadIgnoringLocalCacheData
        for (k, v) in requestHeaderFields {
            req.setValue(v, forHTTPHeaderField: k)
        }

        guard let (data, response) = try? await URLSession.shared.data(for: req) else {
            os_log(.error, "error fetching data for url: \(link.url)")
            return link
        }

        guard (response as? HTTPURLResponse)?.statusCode == 200 else {
            os_log(.error, "error fetching data for url: \(link.url)")
            return link
        }

        if let data = String(data: data, encoding: .utf8),
           let og = DefaultOpenGraphData(html: data) {
            link.ogTitle = og.ogTitle
            link.ogDescription = og.ogDescription
            link.ogImageUrl = og.ogImageUrl
        }

        return link
    }

    public func process(_ links: [Link], batchSize: Int = 10) async throws -> [Link] {
        return try await withThrowingTaskGroup(of: Link.self) { [weak self] group in
            guard let strongSelf = self else { throw QueueError.unknownError }
            for index in 0..<min(links.count, batchSize) {
                group.addTask {
                    return await strongSelf.process(links[index])
                }
            }

            var index = batchSize
            var res = [Link]()
            for try await link in group {
                res.append(link)
                if index < links.count {
                    group.addTask { [index] in
                        return await strongSelf.process(links[index])
                    }
                    index += 1
                }
            }

            return res
        }
    }

    public func imageWorker(_ link: Link) async -> Data? {
        guard let imageUrl = link.ogImageUrl, let url = URL(string: imageUrl) else {
            return nil
        }

        var req = URLRequest(url: url)
        for (k, v) in requestHeaderFields {
            req.setValue(v, forHTTPHeaderField: k)
        }

        guard let (data, response) = try? await URLSession.shared.data(from: url) else {
            return nil
        }

        guard (response as? HTTPURLResponse)?.statusCode == 200 else {
            return nil
        }

        return data
    }

    public func fetchImages(_ links: [Link], batchSize: Int = 10) async throws -> [(Link,Data?)] {
        return try await withThrowingTaskGroup(of: (Link,Data?).self) { [weak self] group in
            guard let strongSelf = self else { throw QueueError.unknownError }
            for index in 0..<min(links.count, batchSize) {
                group.addTask {
                    return (links[index], await strongSelf.imageWorker(links[index]))
                }
            }

            var index = batchSize
            var res = [(Link, Data?)]()

            for try await image in group {
                res.append(image)
                if index < links.count {
                    group.addTask { [index] in
                        return (links[index], await strongSelf.imageWorker(links[index]))
                    }
                    index += 1
                }
            }
            return res
        }
    }
}
