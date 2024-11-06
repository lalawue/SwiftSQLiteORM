//
//  DBSchemaTable.swift
//  SwiftSQLiteORM
//
//  Created by lalawue on 2024/11/6.
//

import Foundation

/// Table definition schema version
struct DBSchemaTable: DBTableDef {

    /// table name
    let name: String
    
    /// table schema version
    let version: Double
    
    private enum TableKeys: String, DBTableKeys {
        case name
        case version
    }

    static var tableKeys: any DBTableKeys.Type {
        return TableKeys.self
    }
    
    static var tableName: String {
        return "schema_version_t"
    }
    
    static var tableVersion: Double {
        return 0
    }
    
    static var databaseName: String {
        return "orm_schema_version.sqlite3"
    }
}
