//
//  DBEngine.swift
//  SwiftSQLiteORM
//
//  Created by lalawue on 2024/11/5.
//

import GRDB

/// database engine for multiple database conneciton
class DBEngine {
    
    /// only one instance
    private static let shared = DBEngine()
    
    /// database location
    private let dirPath: String
    
    private let lock = NSLock()

    /// queues for diference table
    private var queues = DBCache<DBQueue>()

    // MARK: -

    private init() {
        let prefix = NSSearchPathForDirectoriesInDomains(.cachesDirectory, .userDomainMask, true).first ?? ""
        self.dirPath = prefix + "/SwiftSQLiteORM/"
        try? FileManager.default.createDirectory(atPath: self.dirPath, withIntermediateDirectories: true)
        dbLog("dirPath: \(self.dirPath)")
    }
    
    private static func _getQueue<T: DBTableDef>(_ def: T.Type) -> DBQueue {
        let bname = def.databaseName
        if let q = shared.queues[bname] {
            return q
        } else {
            shared.lock.lock()
            let q = shared.queues[bname] ?? DBQueue(shared.dirPath + bname)
            shared.queues[bname] = q
            shared.lock.unlock()
            return q
        }
    }
    
    @inlinable
    static func read<T: DBTableDef>(_ def: T.Type,
                                    _ block: (GRDB.Database) throws -> [T]) throws -> [T]
    {
        return try _getQueue(def).read(block)
    }

    @inlinable
    static func write<T: DBTableDef>(_ def: T.Type,
                                     _ block: (GRDB.Database) throws -> Void) throws
    {
        try _getQueue(def).write(block)
    }
}

/// every queue is database connection (database file)
private class DBQueue {

    private let _queue: GRDB.DatabaseQueue?
    
    init(_ dbPath: String) {
        var pwd = ""
        if let p = DBKeyChain.restorePasswd() {
            pwd = p
        } else if DBKeyChain.storePasswd("SwiftSQLiteORM_\(arc4random())") {
            pwd = DBKeyChain.restorePasswd() ?? ""
        }
        if pwd.isEmpty {
            dbLog(isError: true, "failed to get passwd")
            self._queue = nil
        } else {
            var config = GRDB.Configuration()
            config.prepareDatabase({
                try $0.usePassphrase(pwd)
            })
            self._queue = try? GRDB.DatabaseQueue(path: dbPath, configuration: config)
        }
    }
    
    func read<T>(_ block: (GRDB.Database) throws -> T) throws -> T {
        guard let q = _queue else {
            throw DatabaseError(resultCode: .SQLITE_INTERNAL)
        }
        return try q.read(block)
    }

    func write(_ block: (GRDB.Database) throws -> Void) throws {
        guard let q = _queue else {
            throw DatabaseError(resultCode: .SQLITE_INTERNAL)
        }
        try q.inTransaction(.deferred, { db in
            do {
                try block(db)
                return .commit
            } catch {
                return .rollback
            }
        })
    }
}
