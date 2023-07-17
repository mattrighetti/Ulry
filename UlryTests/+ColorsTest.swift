//
//  +ColorsTest.swift
//  UlryTests
//
//  Created by Mattia Righetti on 11/04/23.
//  Copyright © 2023 Mattia Righetti. All rights reserved.
//

import Foundation

import XCTest
@testable import Ulry

class ColorTest: XCTestCase {
    func testInvalidColor() throws {
        XCTAssertNil(UIColor(hex: "a"))
        XCTAssertNil(UIColor(hex: "aa"))
        XCTAssertNil(UIColor(hex: "abb"))
        XCTAssertNil(UIColor(hex: "aaa"))
        XCTAssertNil(UIColor(hex: "accc"))
        XCTAssertNil(UIColor(hex: "abddeee"))
        XCTAssertNil(UIColor(hex: "#a"))
    }

    func testValidColor() throws {
        XCTAssertNotNil(UIColor(hex: "#aabbbb"))
        XCTAssertNotNil(UIColor(hex: "#aabbaaaa"))
    }
}
