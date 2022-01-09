//
//  UlryTests.swift
//  UlryTests
//
//  Created by Mattia Righetti on 1/9/22.
//

import XCTest
@testable import Ulry

class UlryTests: XCTestCase {
    func testExample() throws {
        let category = Category.all
        
        let group1 = Group()
        group1.name = "Name"
        group1.colorHex = "#333333"
        group1.iconName = "iconname"
        let groupCategory1 = Category.group(group1)
        
        let group2 = Group()
        group2.name = "Name1"
        group2.colorHex = "#333333"
        group2.iconName = "iconname"
        let groupCategory2 = Category.group(group2)
        
        XCTAssert(groupCategory1.hashValue != category.hashValue)
        XCTAssert(groupCategory1.hashValue != groupCategory2.hashValue)
    }
}
