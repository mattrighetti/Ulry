//
//  File.swift
//  
//
//  Created by Mattia Righetti on 18/03/23.
//  Copyright © 2023 Mattia Righetti. All rights reserved.
//

import Foundation
import Kanna


public class HTMLParser {
    private let document: HTMLDocument

    public init?(html: String) {
        guard let document = try? Kanna.HTML(html: html, encoding: .utf8) else { return nil }
        self.document = document
    }

    /// Returns content of `<meta>` tag
    func contentFromMetatag(metatag: String) -> String? {
        guard let content = document.head?.xpath(xpathForMetatag(metatag)).first?["content"] else { return nil }
        return content.isEmpty ? nil : content
    }

    /// Returns page `<title>`, null in case none is found
    func pageTitle() -> String? {
        return document.title
    }

    /// Returns content of an HTML tag located in `<head>` document section
    ///
    /// This is a sample HTML string
    /// ```
    /// <head>
    /// <title>Some Title</title>
    ///     ...
    /// <head>
    /// ```
    ///
    /// calling `contentFromTag(tag: "title")` will return `Some Title`
    func contentFromTag(tag: String) -> String? {
        return document.head?.xpath("//\(tag)").first?.text
    }

    private func xpathForMetatag(_ metatag: String) -> String {
        return "//meta[@property='\(metatag)'] | //meta[@name='\(metatag)']"
    }
}
