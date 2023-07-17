//
//  File.swift
//  
//
//  Created by Matt on 16/12/2022.
//  Copyright © 2022 Mattia Righetti. All rights reserved.
//

import XCTest
@testable import Links

class GroupsTests: XCTestCase {
    func testGroupEqual() {
        let group1 = Group(colorHex: "#aaffaa", iconName: "icon1", name: "name")
        let group2 = Group(colorHex: "#aaffaa", iconName: "icon1", name: "name")
        let group3 = Group(colorHex: "#aafafa", iconName: "icon1", name: "name")
        XCTAssertTrue(group1 === group2)
        XCTAssertFalse(group1 === group3)
        XCTAssertFalse(group2 === group3)
    }

    func testGroupToJson() {
        let group = Group(colorHex: "333333", iconName: "icon", name: "name")

        XCTAssertNoThrow {
            try JSONEncoder().encode(group)
        }

        let data = try! JSONEncoder().encode(group)
        print(String(data: data, encoding: .utf8)!)
    }
}
