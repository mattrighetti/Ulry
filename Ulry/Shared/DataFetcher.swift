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
        let url = link.url.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !url.isEmpty, URL(string: url) != nil else { return }
        
        var og = [String:String]()
        do {
            og = try MetaRod().build(url).og()
        } catch {
            os_log(.error, "🛑 encountered error while fetching URL data")
        }
        
        let imgUrl = og.findFirstValue(keys: URL.imageMeta)
        let title = og.findFirstValue(keys: URL.titleMeta)
        let description = og.findFirstValue(keys: URL.descriptionMeta)
        
        link.ogImageUrl = imgUrl
        link.ogTitle = title
        link.ogDescription = description
        
        guard
            let imgUrl = imgUrl,
                let url = URL(string: imgUrl)
        else {
            handler?()
            return
        }
        
        let imgTask = URLSession.shared.dataTask(with: url) { data, response, error in
            guard let data = data else {
                os_log(.debug, "cannot fetch image for link: \(imgUrl)")
                handler?()
                return
            }
            
            link.imageData = data
            handler?()
        }
        imgTask.resume()
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
