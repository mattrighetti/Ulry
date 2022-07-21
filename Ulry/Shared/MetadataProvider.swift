//
//  MetadataProvider.swift
//  Ulry
//
//  Created by Mattia Righetti on 7/3/22.
//

import os
import UIKit
import LinkPresentation

class MetadataProvider: NSObject {
    static var shared = MetadataProvider()
    
    private override init() {}
    
    public func fetchLinkMetadata(link: Link) {
        guard let url = URL(string: link.url) else { return }
        
        let lp = LPMetadataProvider()
        lp.startFetchingMetadata(for: url) { metadata, error in
            guard error == nil, metadata != nil else { return }
            
            link.ogTitle = metadata?.title
            link.ogDescription = metadata?.value(forKey: "summary") as? String
            
            _ = Database.main.update(link)
            
            if let imageProvider = metadata!.imageProvider {
                imageProvider.loadObject(ofClass: UIImage.self) { img, error in
                    guard
                        let image = img as? UIImage,
                        let path = ImageStorage.shared.storeImage(image, filename: "\(link.id).jpeg")
                    else { return }
                    
                    link.ogImageUrl = path
                    _ = Database.main.update(link)
                }
            }
        }
    }
    
    
}
