//
//  File.swift
//  
//
//  Created by Matt on 15/12/2022.
//  Copyright © 2022 Mattia Righetti. All rights reserved.
//

import XCTest
@testable import LinksDatabase

final class SQLTests: XCTestCase {
    func testSelectQueryGenerator() {
        XCTAssertEqual("select * from table", _sql_select("*", from: "table", where: nil, orderBy: nil))
        XCTAssertEqual("select * from table where id = 4", _sql_select("*", from: "table", where: "id = 4", orderBy: nil))
        XCTAssertEqual("select * from table where id = 4 order by val collate nocase desc", _sql_select("*", from: "table", where: "id = 4", orderBy: ("val", "desc")))
        XCTAssertEqual("select * from table order by o collate nocase asc", _sql_select("*", from: "table", where: nil, orderBy: ("o", "asc")))
    }

    func testUpdateQueryGenerator() {
        XCTAssertEqual(
            "update link set url = ?,starred = ?,unread = ?,color = ?,updated_at = ?,ogTitle = ?,ogImageUrl = ?,ogDescription = ? where id = ?",
            _sql_update("link", fields: ["url", "starred", "unread", "color", "updated_at", "ogTitle", "ogImageUrl", "ogDescription"], where: "id = ?")
        )
    }

    func testInsertQueryGenerator() {
        XCTAssertEqual("insert into link (first,second,third) values (?,?,?)", _sql_insert(into: "link", fields: ["first", "second", "third"]))
    }
}
