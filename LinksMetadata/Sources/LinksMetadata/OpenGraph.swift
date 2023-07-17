//
//  File.swift
//  
//
//  Created by Matt on 13/11/2022.
//  Copyright © 2022 Mattia Righetti. All rights reserved.
//

import Foundation

public protocol OpenGraph {
    var url: String? { get }
    var ogImageUrl: String? { get set }
    var ogTitle: String? { get set }
    var ogDescription: String? { get set }
    var ogSiteName: String? { get set }
}

public struct DefaultOpenGraphData: OpenGraph {
    public var url: String?
    public var ogImageUrl: String?
    public var ogTitle: String?
    public var ogDescription: String?
    public var ogSiteName: String?

    public init?(html: String) {
        guard let parser = HTMLParser(html: html) else { return nil }
        url = parser.contentFromMetatag(metatag: "og:url")
        ogTitle = parser.contentFromMetatag(metatag: "og:title") ?? parser.pageTitle() ?? nil
        ogImageUrl = parser.contentFromMetatag(metatag: "og:image")
        ogDescription = parser.contentFromMetatag(metatag: "og:description")
        ogSiteName = parser.contentFromMetatag(metatag: "og:site_name")
    }
}
