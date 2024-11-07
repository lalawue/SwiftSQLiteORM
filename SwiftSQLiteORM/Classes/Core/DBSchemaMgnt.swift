//
//  DBSchemaTable.swift
//  SwiftSQLiteORM
//
//  Created by lalawue on 2024/11/6.
//

import Foundation
import GRDB

/// Table definition schema version
struct DBSchemaTable: DBTableDef {

    /// table name
    let name: String
    
    /// table schema version
    let version: Double
    
    /// all column names
    let columns: [String]
    
    fileprivate enum TableKeys: String, DBTableKeys {
        case name
        case version
        case columns
    }

    static var tableKeys: any DBTableKeys.Type {
        return TableKeys.self
    }
    
    static var tableName: String {
        return "orm_table_schema_t"
    }
    
    static var schemaVersion: Double {
        return 0
    }
    
    static var databaseName: String {
        return "orm_table_schema.sqlite3"
    }
}

/// record table name, schema, columns' name
class DBSchemaMgnt {
    
    private var schemaCache = DBCache<DBSchemaTable>()
    
    private static let shared = DBSchemaMgnt()
    
    private init() {
    }
    
    /// get table schema from mem or from database
    static func getSchema<T: DBTableDef>(db: Database, _ ttype: T.Type, _ tname: String) throws -> DBSchemaTable? {
        if let s = shared.schemaCache[tname] {
            return s
        }
        let stype = DBSchemaTable.self
        let rtype = DBTableRecord<DBSchemaTable>.self
        let sql = "SELECT * FROM \(stype.tableName) WHERE \(stype.TableKeys.name) = ?"
        return try rtype.fetchAll(db: db, sql: sql, arguments: [tname]).first
    }

    /// set table schema to mem and database
    static func setSchema<T: DBTableDef>(db: Database, _ ttype: T.Type, _ tname: String) throws {
        let s = DBSchemaTable(name: tname, version: ttype.schemaVersion, columns: ttype.tableKeys.allKeyNames())
        shared.schemaCache[tname] = s
        try DBTableRecord<DBSchemaTable>.pushAll(db: db, values: [s])
    }
}
