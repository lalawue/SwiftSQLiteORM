//
//  DBEngine.swift
//  SwiftSQLiteORM
//
//  Created by lalawue on 2024/11/5.
//

import GRDB

/// Database Engine for internal
final class DBEngine {

    /// database location
    private let dirPath: String

    /// database queue
    private lazy var queue: GRDB.DatabaseQueue? = {
        var pwd = ""
        if let p = KeyChainPwd.getPwdString() {
            pwd = p
        } else if KeyChainPwd.setPwdString("\(arc4random())_SwiftSQLiteORM") {
            pwd = KeyChainPwd.getPwdString() ?? ""
        }
        if pwd.isEmpty {
            return nil
        }
        var config = GRDB.Configuration()
        config.prepareDatabase({
            try $0.usePassphrase(pwd)
        })
        return try? GRDB.DatabaseQueue(path: self.dirPath, configuration: config)
    }()

    /// only one instance
    private static let shared = DBEngine()

    // MARK: -

    private init() {
        let prefix = NSSearchPathForDirectoriesInDomains(.cachesDirectory, .userDomainMask, true).first ?? ""
        self.dirPath = prefix + "/SwiftSQLiteORM/"
    }

    static func read<T>(_ block: (GRDB.Database) throws -> T) throws -> T? {
        guard let q = shared.queue else {
            throw DatabaseError(resultCode: .SQLITE_INTERNAL)
        }
        return try q.read(block)
    }

    static func write(_ block: (GRDB.Database) throws -> Void) throws {
        guard let q = shared.queue else {
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
