//
//  File.swift
//  
//
//  Created by Matt on 16/12/2022.
//  Copyright © 2022 Mattia Righetti. All rights reserved.
//

import XCTest
@testable import Links

class TagsTests: XCTestCase {
    func testTagEquals() {
        let tag1 = Tag(colorHex: "#aaffaa", name: "name1")
        let tag2 = Tag(colorHex: "#aaffaa", name: "name1")
        let tag3 = Tag(colorHex: "#aafaaa", name: "name1")
        let tag4 = Tag(colorHex: "#aaffaa", name: "name")
        XCTAssertTrue(tag1 === tag2)
        XCTAssertFalse(tag3 === tag2)
        XCTAssertFalse(tag3 === tag1)
        XCTAssertFalse(tag4 === tag2)
        XCTAssertFalse(tag4 === tag1)
        XCTAssertFalse(tag4 === tag3)
    }

    func testTagToJson() {
        let tag = Tag(colorHex: "333333", name: "name")

        XCTAssertNoThrow {
            try JSONEncoder().encode(tag)
        }

        let data = try! JSONEncoder().encode(tag)
        print(String(data: data, encoding: .utf8)!)
    }
}
