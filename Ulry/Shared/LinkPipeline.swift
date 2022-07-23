//
//  LinkPipeline.swift
//  Ulry
//
//  Created by Mattia Righetti on 7/22/22.
//

import os
import Foundation
import LinkPresentation
import FMDB

final class LinkPipeline {
    static var main = LinkPipeline()
    
    private init() {}
    
    func save(link: Link) {
        Task {
            await process(link)
        }
    }
    
    func save(links: [Link]) {
        for link in links {
            DispatchQueue.global(qos: .background).async {
                Task {
                    os_log(.debug, "TRIGGERING FETCHING")
                    await self.process(link)
                }
            }
        }
    }
    
    private func process(_ link: Link) async {
        let md = try? await fetchMetadata(for: link)
        
        link.ogTitle = md?.title
        link.ogDescription = md?.value(forKey: "summary") as? String
        
        if let imageProvider = md?.imageProvider, let image = await fetchImage(with: imageProvider) {
            link.ogImageUrl = ImageStorage.shared.storeImage(image, filename: "\(link.id).jpeg")
        }
        
        store(link)
    }
    
    private func store(_ link: Link) {
        if !Database.main.existsLink(with: link.url) {
            Database.main.insertInQueue(link)
        } else {
            Database.main.updateInQueue(link)
        }
    }
    
    private func fetchMetadata(for link: Link) async throws -> LPLinkMetadata? {
        return try await withCheckedThrowingContinuation { continuation in
            let lp = LPMetadataProvider()
            DispatchQueue.main.async {
                lp.startFetchingMetadata(for: URL(string: link.url)!) { metadata, error in
                    DispatchQueue.global(qos: .background).async {
                        guard error == nil else {
                            continuation.resume(returning: nil)
                            return
                        }
                        continuation.resume(returning: metadata)
                    }
                }
            }
        }
    }
    
    private func fetchImage(with imageProvider: NSItemProvider?) async -> UIImage? {
        guard let imageProvider = imageProvider else { return nil }
        
        return await withCheckedContinuation { continuation in
            imageProvider.loadObject(ofClass: UIImage.self) { img, err in
                DispatchQueue.main.async {
                    guard err == nil, let image = img as? UIImage else {
                        continuation.resume(returning: nil)
                        return
                    }
                    continuation.resume(returning: image)
                }
            }
        }
    }
}
