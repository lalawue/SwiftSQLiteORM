//
//  DBWrapper.swift
//  SwiftSQLiteORM
//
//  Created by lalawue on 2024/11/6.
//

import GRDB

/// database management interface
final class DBMgnt {
    
    // MARK: -
    
    private static let shared = DBMgnt()
    
    private init() {
    }
    
    public static func createTable(_ tbl: DBTableDef.Type) {
        try? DBEngine.read(tbl, {
            if let s = try DBSchemaMgnt.getSchema(db: $0, tbl, tbl.tableName), s.version >= tbl.schemaVersion {
                return
            }
            // FIXME: create table or alter table columns
        })
    }
}
