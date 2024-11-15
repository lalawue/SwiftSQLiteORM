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
    
    // database path
    static var databasePath: String {
        return shared.dirPath
    }

    // MARK: -

    private init() {
        let prefix = NSSearchPathForDirectoriesInDomains(.cachesDirectory, .userDomainMask, true).first ?? ""
        self.dirPath = prefix + "/SwiftSQLiteORM/"
        try? FileManager.default.createDirectory(atPath: self.dirPath, withIntermediateDirectories: true)
        dbLog("dirPath: \(self.dirPath)")
    }
    
    private static func _getQueue<T: DBTableDef>(_ def: T.Type) throws -> DBQueue {
        let bname = def.databaseName
        if let q = shared.queues[bname] {
            return q
        } else {
            shared.lock.lock()
            defer { shared.lock.unlock() }
            let q = try (shared.queues[bname] ?? DBQueue(shared.dirPath + bname))
            shared.queues[bname] = q
            return q
        }
    }
        
    @inlinable
    static func read<T: DBTableDef>(_ def: T.Type,
                                    _ block: (GRDB.Database) throws -> [T]) throws -> [T]
    {
        return try _getQueue(def).read(T.databaseName, block)
    }

    @inlinable
    static func write<T: DBTableDef>(_ def: T.Type,
                                     _ block: (GRDB.Database) throws -> Void) throws
    {
        try _getQueue(def).write(T.databaseName, block)
    }
}

/// every queue is database connection (database file)
private class DBQueue {

    private let _queue: GRDB.DatabaseQueue
    
    init(_ dbPath: String) throws {
        var pwd = ""
        if let p = DBKeyChain.restorePasswd() {
            pwd = p
        } else if DBKeyChain.storePasswd("SwiftSQLiteORM_\(arc4random())") {
            pwd = DBKeyChain.restorePasswd() ?? ""
        }
        if pwd.isEmpty {
            dbLog(isError: true, "failed to get database config's passwd")
            throw DBORMError.FailedToGetCipherPasswd(dbPath: dbPath)
        } else {
            var config = GRDB.Configuration()
            config.prepareDatabase({
                try $0.usePassphrase(pwd)
            })
            do {
                self._queue = try GRDB.DatabaseQueue(path: dbPath, configuration: config)
            } catch {
                throw DBORMError.FailedToCreateDBQueue(dbPath: dbPath, error: error)
            }
        }
    }
    
    func read<T>(_ dbname: String, _ block: (GRDB.Database) throws -> T) throws -> T {
        try _queue.read(block)
    }

    func write(_ dbname: String, _ block: (GRDB.Database) throws -> Void) throws {
        var in_error: Error? = nil
        try _queue.inTransaction(.deferred, { db in
            do {
                try block(db)
                return .commit
            } catch {
                in_error = error
                return .rollback
            }
        })
        if let err = in_error {
            throw err
        }
    }
}
