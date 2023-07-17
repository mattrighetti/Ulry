//
//  File.swift
//  
//
//  Created by Matt on 26/01/2023.
//  Copyright © 2023 Mattia Righetti. All rights reserved.
//

import FMDB
import Foundation

final class MigrationsTable: DatabaseTable {
    let name: String
    private let queue: DatabaseQueue

    init(name: String, queue: DatabaseQueue) {
        self.name = name
        self.queue = queue
    }

    func fetchLastRunMigration() throws -> Int32? {
        return try fetchSingleGeneric { database in
            guard let resultSet = database.executeQuery("select max(version) as version from migrations;", withArgumentsIn: []) else { return nil }
            if resultSet.next() {
                return resultSet.int(forColumn: "version")
            }
            return nil
        }
    }

    private func fetchSingleGeneric<T>(_ fetchMethod: @escaping ((FMDatabase) -> T?)) throws -> T? {
        var t: T? = nil
        var error: DatabaseError? = nil

        queue.runInDatabaseSync { databaseResult in
            if case .failure(let databaseError) = databaseResult {
                error = databaseError
            }

            if case .success(let database) = databaseResult {
                t = fetchMethod(database)
            }
        }

        if let error = error {
            throw(error)
        }

        return t
    }
}
