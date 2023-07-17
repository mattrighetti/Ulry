//
//  File.swift
//  
//
//  Created by Mattia Righetti on 20/03/23.
//  Copyright © 2023 Mattia Righetti. All rights reserved.
//

import XCTest
@testable import LinksMetadata

private let urls: [URL] = [
    "https://www.avanderlee.com/swift/operations/",
    "https://www.swiftbysundell.com/podcast/121/",
    "https://www.rfc-editor.org/rfc/rfc6762#page-5",
    "https://matheducators.stackexchange.com/questions/7985/solving-linear-equations-by-factoring",
]
.map { URL(string: $0)! }

let html1 = """
<html lang="en" op="news">
    <head>
    <meta name="referrer" content="origin">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <link rel="stylesheet" type="text/css" href="news.css?b2DHICJ3VDzltQrbLwgg">
    <link rel="shortcut icon" href="favicon.ico">
    <link rel="alternate" type="application/rss+xml" title="RSS" href="rss">
    <title>Hacker News</title>
    <sometag>Content</sometag>
    </head>
<body></body>
</html>
"""

final class HTMLParserTests: XCTestCase {
    func testTitleUrl1() throws {
        let html = try String(contentsOf: urls[2])
        let parser = HTMLParser(html: html)!
        XCTAssertEqual(nil, parser.contentFromMetatag(metatag: "og:url"))
        XCTAssertEqual("RFC 6762: Multicast DNS", parser.pageTitle()!)
    }

    func testTitleUrl2() throws {
        let html = try String(contentsOf: urls[3])
        let parser = HTMLParser(html: html)!
        XCTAssertEqual("https://matheducators.stackexchange.com/questions/7985/solving-linear-equations-by-factoring", parser.contentFromMetatag(metatag: "og:url")!)
        XCTAssertEqual("secondary education - Solving linear equations by factoring - Mathematics Educators Stack Exchange", parser.pageTitle()!)
    }

    func testTagUrl3() throws {
        let parser = HTMLParser(html: html1)
        XCTAssertEqual("Content", parser?.contentFromTag(tag: "sometag"))
        XCTAssertEqual("Hacker News", parser?.contentFromTag(tag: "title"))
    }
}
