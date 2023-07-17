//
//  File.swift
//  
//
//  Created by Matt on 15/12/2022.
//  Copyright © 2022 Mattia Righetti. All rights reserved.
//

import Foundation

// MARK: - SQL

func _sql_select(_ s: String, from: String, where: String?, orderBy: (String, String)?) -> String {
    var query = "select \(s) from \(from)"
    if let w = `where` {
        query += " where " + w
    }
    if let oc = orderBy {
        query += " order by \(oc.0) collate nocase \(oc.1)"
    }
    return query
}

func _sql_delete(from: String, where: String?) -> String {
    var query = "delete from \(from)"
    if let w = `where` {
        query += " where \(w)"
    }
    return query
}

func _sql_insert(into table: String, fields: [String]) -> String {
    return "insert into \(table) (" + fields.joined(separator: ",") + ") values (" + [String](repeating: "?", count: fields.count).joined(separator: ",") + ")"
}

func _sql_update(_ table: String, fields: [String], where: String) -> String {
    guard fields.count > 0 else { fatalError("update function must have at least a sql field to update") }

    var query = "update \(table) set " + fields.map { "\($0) = ?" }.joined(separator: ",")
    query += " where \(`where`)"
    return query
}
