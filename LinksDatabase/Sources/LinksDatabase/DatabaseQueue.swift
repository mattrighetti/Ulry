//
//  DatabaseQueue.swift
//  Ulry
//
//  Created by Matt on 06/11/2022.
//  Copyright © 2022 Mattia Righetti. All rights reserved.
//

import FMDB

public typealias DatabaseBlockResult = Result<FMDatabase, DatabaseError>
public typealias DatabaseBlock = (DatabaseBlockResult) -> Void

extension DatabaseBlockResult {
    /// Convenience for getting the database from a DatabaseResult.
    var database: FMDatabase? {
        switch self {
        case .success(let database):
            return database
        case .failure:
            return nil
        }
    }

    /// Convenience for getting the error from a DatabaseResult.
    var error: DatabaseError? {
        switch self {
        case .success:
            return nil
        case .failure(let error):
            return error
        }
    }
}

public enum DatabaseError: String, Equatable, Error {
    case isSuspended = "IS SUSPENDED"
    case uniqueConstraintFailed = "UNIQUE constraint failed"
    case outOfMemory = "out of memory"

    init(_ code: Int) {
        switch code {
        case 7: self = .outOfMemory
        case 19: self = .uniqueConstraintFailed
        default: fatalError()
        }
    }

    init(_ error: Error) {
        let nserror = error as NSError
        self.init(nserror.code)
    }
}

public final class DatabaseQueue {

    /// Check to see if the queue is suspended. Read-only.
    /// Calling suspend() and resume() will change the value of this property.
    /// This will return true only on iOS — on macOS it’s always false.
    public var isSuspended: Bool {
        #if os(iOS)
        precondition(Thread.isMainThread)
        return _isSuspended
        #else
        return false
        #endif
    }

    private var _isSuspended: Bool = false
    private var isCallingDatabase = false
    private let database: FMDatabase
    private let databasePath: String
    private let serialDispatchQueue: DispatchQueue
    private let targetDispatchQueue: DispatchQueue
    #if os(iOS)
    private let databaseLock = NSLock()
    #endif

    init(databasePath: String) {
        precondition(Thread.isMainThread)
        self.serialDispatchQueue = DispatchQueue(label: "DatabaseQueue (Serial) - \(databasePath)", attributes: .initiallyInactive)
        self.targetDispatchQueue = DispatchQueue(label: "DatabaseQueue (Target) - \(databasePath)")
        self.serialDispatchQueue.setTarget(queue: self.targetDispatchQueue)
        self.serialDispatchQueue.activate()

        self.databasePath = databasePath
        self.database = FMDatabase(path: databasePath)
        openDatabase()
        _isSuspended = false
    }

    // MARK: - Make Database Calls

    /// Run a DatabaseBlock synchronously. This call will block the main thread
    /// potentially for a while, depending on how long it takes to execute
    /// the DatabaseBlock *and* depending on how many other calls have been
    /// scheduled on the queue. Use sparingly — prefer async versions.
    public func runInDatabaseSync(_ databaseBlock: DatabaseBlock) {
        precondition(Thread.isMainThread)
        serialDispatchQueue.sync {
            self._runInDatabase(self.database, databaseBlock, false)
        }
    }

    /// Run a DatabaseBlock asynchronously.
    public func runInDatabase(_ databaseBlock: @escaping DatabaseBlock) {
        precondition(Thread.isMainThread)
        serialDispatchQueue.async {
            self._runInDatabase(self.database, databaseBlock, false)
        }
    }

    /// Run a DatabaseBlock wrapped in a transaction synchronously.
    /// Transactions help performance significantly when updating the database.
    /// Nevertheless, it’s best to avoid this because it will block the main thread —
    /// prefer the async `runInTransaction` instead.
    public func runInTransactionSync(_ databaseBlock: @escaping DatabaseBlock) {
        precondition(Thread.isMainThread)
        serialDispatchQueue.sync {
            self._runInDatabase(self.database, databaseBlock, true)
        }
    }

    /// Run a DatabaseBlock wrapped in a transaction asynchronously.
    /// Transactions help performance significantly when updating the database.
    public func runInTransaction(_ databaseBlock: @escaping DatabaseBlock) {
        precondition(Thread.isMainThread)
        serialDispatchQueue.async {
            self._runInDatabase(self.database, databaseBlock, true)
        }
    }

    /// Run all the lines that start with "create".
    /// Use this to create tables, indexes, etc.
    public func runCreateStatements(_ statements: String) throws {
        precondition(Thread.isMainThread)
        var error: DatabaseError? = nil
        runInDatabaseSync { result in
            switch result {
            case .success(let database):
                statements.enumerateLines { (line, stop) in
                    if line.lowercased().hasPrefix("create") {
                        database.executeStatements(line)
                    }
                    stop = false
                }
            case .failure(let databaseError):
                error = databaseError
            }
        }
        if let error = error {
            throw(error)
        }
    }

    public func vacuum() {
        precondition(Thread.isMainThread)
        runInDatabase { res in
            res.database?.executeStatements("vacuum;")
        }
    }

    /// Run migrations synchronously
    public func runMigrations(_ statements: String) throws {
        precondition(Thread.isMainThread)
        var error: DatabaseError? = nil
        runInDatabaseSync { result in
            switch result {
            case .success(let database):
                statements.enumerateLines { line, stop in
                    if line.lowercased().starts(with: "insert") {
                        database.executeUpdate(line, withArgumentsIn: [])
                    } else if !line.isEmpty {
                        database.executeStatements(line)
                    }
                }
            case .failure(let databaseError):
                error = databaseError
            }
        }
        if let error = error {
            throw(error)
        }
    }

    /// Vacuum the database if it’s been more than `daysBetweenVacuums` since the last vacuum.
    /// Normally you would call this right after initing a DatabaseQueue.
    ///
    /// - Returns: true if database will be vacuumed.
    @discardableResult
    public func vacuumIfNeeded(daysBetweenVacuums: Int) -> Bool {
        precondition(Thread.isMainThread)
        let defaultsKey = "DatabaseQueue-LastVacuumDate-\(databasePath)"
        let minimumVacuumInterval = TimeInterval(daysBetweenVacuums * (60 * 60 * 24)) // Doesn’t have to be precise
        let now = Date()
        let cutoffDate = now - minimumVacuumInterval
        if let lastVacuumDate = UserDefaults.standard.object(forKey: defaultsKey) as? Date {
            if lastVacuumDate < cutoffDate {
                vacuum()
                UserDefaults.standard.set(now, forKey: defaultsKey)
                return true
            }
            return false
        }

        // Never vacuumed — almost certainly a new database.
        // Just set the LastVacuumDate pref to now and skip vacuuming.
        UserDefaults.standard.set(now, forKey: defaultsKey)
        return false
    }

}

private extension DatabaseQueue {

    func lockDatabase() {
        #if os(iOS)
        databaseLock.lock()
        #endif
    }

    func unlockDatabase() {
        #if os(iOS)
        databaseLock.unlock()
        #endif
    }

    func _runInDatabase(_ database: FMDatabase, _ databaseBlock: (Result<FMDatabase, DatabaseError>) -> Void, _ useTransaction: Bool) {
        lockDatabase()
        defer {
            unlockDatabase()
        }

        precondition(!isCallingDatabase)

        isCallingDatabase = true
        autoreleasepool {
            if _isSuspended {
                return databaseBlock(.failure(.isSuspended))
            }

            if useTransaction {
                database.beginTransaction()
            }
            databaseBlock(.success(database))
            if useTransaction {
                database.commit()
            }
        }
        isCallingDatabase = false
    }

    func openDatabase() {
        database.open()
        database.executeStatements("PRAGMA synchronous = 1;")
        database.shouldCacheStatements = true
    }

}
