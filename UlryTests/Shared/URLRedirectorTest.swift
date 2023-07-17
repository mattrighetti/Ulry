//
//  URLRedirectorTest.swift
//  UlryTests
//
//  Created by Mattia Righetti on 10/19/22.
//  Copyright © 2022 Mattia Righetti. All rights reserved.
//

import Foundation

import XCTest
@testable import Ulry

class URLRedirectorTest: XCTestCase {
    
    func testRegexRedirectUrl() {
        var redirector = URLRedirector()
        redirector.setCustomRedirect([
            .twitter: true,
            .youtube: true,
            .reddit: true,
            .medium: true
        ])
        
        let youtubeUrl = URL(string: "https://www.youtube.com/watch?v=ZSZmibBPj2A")!
        let twitterUrl = URL(string: "https://twitter.com/randompicker")!
        
        let invidiousRedirect = redirector.redirect(youtubeUrl)
        let nitterRedirect = redirector.redirect(twitterUrl)
        
        XCTAssertNotNil(nitterRedirect)
        XCTAssertNotNil(invidiousRedirect)
        
        XCTAssertEqual(URL(string: "https://farside.link/piped/watch?v=ZSZmibBPj2A")!, invidiousRedirect)
        XCTAssertEqual(URL(string: "https://farside.link/nitter/randompicker"), nitterRedirect)
    }
    
    func testRegexRedirectMapUrl() {
        var redirector = URLRedirector()
        redirector.setCustomRedirect([
            .twitter: true,
            .youtube: true,
            .reddit: true,
            .medium: true
        ])
        
        let youtubeUrl = URL(string: "https://www.youtube.com/watch?v=ZSZmibBPj2A")!
        let twitterUrl = URL(string: "https://twitter.com/randompicker")!
        let hdblogitUrl = URL(string: "https://hdblog.it/randompicker")!
        let hdblogcomUrl = URL(string: "https://www.hdblog.net/randompicker")!
        let hdblognetUrl = URL(string: "https://hdblog.it/randompicker")!
        
        let ytRedirect = redirector.redirect(youtubeUrl)
        let nitterRedirect = redirector.redirect(twitterUrl)
        let hdblogitRedirect = redirector.redirect(hdblogitUrl)
        let hdblogcomRedirect = redirector.redirect(hdblogcomUrl)
        let hdblognetRedirect = redirector.redirect(hdblognetUrl)
        
        XCTAssertNotNil(nitterRedirect)
        XCTAssertNotNil(ytRedirect)
        XCTAssertNotNil(hdblogitRedirect)
        XCTAssertNotNil(hdblogcomRedirect)
        XCTAssertNotNil(hdblognetRedirect)
        
        XCTAssertEqual(URL(string: "https://farside.link/piped/watch?v=ZSZmibBPj2A")!, ytRedirect)
        XCTAssertEqual(URL(string: "https://farside.link/nitter/randompicker"), nitterRedirect)
        XCTAssertEqual(URL(string: "https://hdblog.it/randompicker"), hdblogitRedirect)
        XCTAssertEqual(URL(string: "https://hdblog.it/randompicker"), hdblognetRedirect)
        XCTAssertEqual(URL(string: "https://www.hdblog.net/randompicker"), hdblogcomRedirect)
    }
}
