//
//  DBEngine.swift
//  SwiftSQLiteORM
//
//  Created by lalawue on 2024/11/5.
//

import GRDB

/// Database Engine for internal
final class DBEngine {
    
    /// only one instance
    private static let shared = DBEngine()
    
    /// database location
    private let dirPath: String

    /// queues for diference table
    private var queues: DBRWLock<[String: DBQueue]> = DBRWLock([:])

    // MARK: -

    private init() {
        let prefix = NSSearchPathForDirectoriesInDomains(.cachesDirectory, .userDomainMask, true).first ?? ""
        self.dirPath = prefix + "/SwiftSQLiteORM/"
        try? FileManager.default.createDirectory(atPath: self.dirPath, withIntermediateDirectories: true)
        dbLog("dirPath: \(self.dirPath)")
    }
    
    private static func _getQueue(_ tbl: DBTableDef.Type) -> DBQueue {
        let tname = tbl.tableName
        if let q = shared.queues.read({ $0[tname] }) {
            return q
        } else {
            var q: DBQueue?
            shared.queues.write({
                q = DBQueue(shared.dirPath + tbl.databaseName)
                $0[tname] = q
            })
            return q!
        }
    }
    
    @inline(__always)
    static func read<T>(_ tbl: DBTableDef.Type, _ block: (GRDB.Database) throws -> T) throws -> T? {
        return try _getQueue(tbl).read(block)
    }

    @inline(__always)
    static func write(_ tbl: DBTableDef.Type, _ block: (GRDB.Database) throws -> Void) throws {
        try _getQueue(tbl).write(block)
    }
}

final class DBQueue {

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
    
    func read<T>(_ block: (GRDB.Database) throws -> T) throws -> T? {
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
