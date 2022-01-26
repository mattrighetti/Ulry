//
//  DataFetcher.swift
//  Ulry
//
//  Created by Mattia Righetti on 1/19/22.
//

import os
import Foundation

class DataFetcher {
    let urlSession = URLSession.shared
    
    func fetchData(for link: Link, completion handler: (() -> Void)? = nil) {
        os_signpost(.begin, log: OSLog(subsystem: "com.mattrighetti.Ulry", category: .pointsOfInterest), name: "fetchSingleData")
        let url = link.url.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !url.isEmpty, URL(string: url) != nil else { return }
        
        var og = [String:String]()
        os_signpost(.begin, log: OSLog(subsystem: "com.mattrighetti.Ulry", category: .pointsOfInterest), name: "parseOG")
        do {
            og = try MetaRod().build(url).og()
        } catch {
            os_log(.error, "🛑 encountered error while fetching URL data")
        }
        os_signpost(.end, log: OSLog(subsystem: "com.mattrighetti.Ulry", category: .pointsOfInterest), name: "parseOG")
        
        let imgUrl = og.findFirstValue(keys: URL.imageMeta)
        let title = og.findFirstValue(keys: URL.titleMeta)
        let description = og.findFirstValue(keys: URL.descriptionMeta)
        
        link.ogImageUrl = imgUrl
        link.ogTitle = title
        link.ogDescription = description
        
        if let imgUrl = imgUrl, let url = URL(string: imgUrl) {
            let imgTask = URLSession.shared.dataTask(with: url) { data, response, error in
                guard let data = data else {
                    os_log(.debug, "cannot fetch image for link: \(imgUrl)")
                    handler?()
                    return
                }
                
                link.imageData = data
                os_signpost(.end, log: OSLog(subsystem: "com.mattrighetti.Ulry", category: .pointsOfInterest), name: "fetchSingleData")
                handler?()
            }
            imgTask.resume()
        } else {
            os_signpost(.end, log: OSLog(subsystem: "com.mattrighetti.Ulry", category: .pointsOfInterest), name: "fetchSingleData")
            handler?()
        }
    }
    
    func fetchData(for links: [Link], completion handler: (() -> Void)? = nil) {
        let dataGroup = DispatchGroup()
        
        links.forEach { [weak self] link in
            dataGroup.enter()
            self?.fetchData(for: link, completion: {
                dataGroup.leave()
            })
        }
        
        dataGroup.notify(queue: .main) {
            handler?()
        }
    }
}
