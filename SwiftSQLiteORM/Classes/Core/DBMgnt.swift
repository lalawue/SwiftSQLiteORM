//
//  DBWrapper.swift
//  SwiftSQLiteORM
//
//  Created by lalawue on 2024/11/6.
//

import GRDB

/// database management interface
final class DBMgnt {

    /// record whether table was created / altered at the very beginning
    private let flagCache = DBCache<Bool>()
    
    private static let shared = DBMgnt()
    
    private init() {
    }
    
    /// create or alter table if needed
    static func createTable<T: DBTableDef>(_ tbl: T.Type) throws {
        let tname = tbl.tableName
        
        if let _ = shared.flagCache[tname] {
            return
        }
        shared.flagCache[tname] = true
        
        try DBEngine.write(tbl, { db in
            guard let s = try DBSchemaMgnt.getSchema(db: db, tbl, tname) else {
                try DBTableRecord<T>.createTable(db: db)
                return
            }
            guard tbl.schemaVersion >= s.version else {
                return
            }
            // FIXME: alter table, add columns
        })
    }
}
