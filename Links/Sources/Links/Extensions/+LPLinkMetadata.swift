//
//  File.swift
//  
//
//  Created by Matt on 09/12/2022.
//  Copyright © 2022 Mattia Righetti. All rights reserved.
//

import LinkPresentation

public protocol LinkImageProvider {
    func getImageFileURL(for link: Link) -> URL?
}

public extension LPLinkMetadata {
    convenience init(_ link: Link, imageProvider: LinkImageProvider?) {
        self.init()
        self.url = URL(string: link.hostname)
        self.originalURL = URL(string: link.url)
        self.title = link.ogTitle
        if let imageUrl = imageProvider?.getImageFileURL(for: link) {
            self.imageProvider = NSItemProvider(contentsOf: imageUrl)
        }
    }
}
