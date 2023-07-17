//
//  File.swift
//  
//
//  Created by Matt on 09/12/2022.
//

import UIKit
import LinkPresentation

public class LinkActivity: NSObject, UIActivityItemSource {
    var link: Link
    var imageProvider: LinkImageProvider

    public init(_ link: Link, imageProvider: LinkImageProvider) {
        self.link = link
        self.imageProvider = imageProvider
    }

    public func activityViewControllerPlaceholderItem(_ activityViewController: UIActivityViewController) -> Any {
        return link.hostname
    }

    public func activityViewController(_ activityViewController: UIActivityViewController, itemForActivityType activityType: UIActivity.ActivityType?) -> Any? {
        return link.url
    }

    public func activityViewControllerLinkMetadata(_ activityViewController: UIActivityViewController) -> LPLinkMetadata? {
        LPLinkMetadata(link, imageProvider: imageProvider)
    }
}
