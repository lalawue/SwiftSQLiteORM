//
//  DBSchemaHelper.swift
//  SwiftSQLiteORM
//
//  Created by lalawue on 2024/11/6.
//

import Foundation
import GRDB

/// Table definition schema version
struct DBSchemaTable: DBTableDef {

    typealias ORMKey = SchemaTableKeys

    /// table name
    let tname: String

    /// table schema version
    let tversion: Double

    /// all column names
    let tcolumns: [String]
    
    enum SchemaTableKeys: String, DBTableKey {
        case tname = "name"
        case tversion = "version"
        case tcolumns = "columns"
    }
    
    static var primaryKey: ORMKey? {
        return .tname
    }

    static var tableKeys: ORMKey.Type {
        return SchemaTableKeys.self
    }

    static var tableName: String {
        return "orm_table_schema_t"
    }

    static var tableVersion: Double {
        return 0
    }

    static var databaseName: String {
        return "orm_table_schema.sqlite"
    }
}

/// record table name, schema version, all column names
class DBSchemaHelper {
    
    private static var _schemaCache = DBCache<DBSchemaTable>()

    private init() {
    }

    /// get table schema from mem or from database
    static func getSchema<T: DBTableDef>(_ def: T.Type) throws -> DBSchemaTable? {
        let tname = def.tableName
        if let sdata = _schemaCache[tname] {
            return sdata
        }
        let sdef = DBSchemaTable.self
        let sql = "SELECT * FROM '\(sdef.tableName)' WHERE '\(sdef.ORMKey.tname)' = '\(tname)'"
        return try DBEngine.read(sdef, { db in
            return try sdef._fetch(db: db, sql: sql)
        }).first
    }
    
    /// set table schema to mem and database
    static func setSchema<T: DBTableDef>(_ def: T.Type) throws {
        let tname = def.tableName
        let p2c = def._nameMapping().p2c
        let sdata = DBSchemaTable(tname: tname, tversion: def.tableVersion, tcolumns: Array(p2c.keys))
        _schemaCache[tname] = sdata
        let sdef = DBSchemaTable.self
        try DBEngine.write(sdef, { db in
            try sdef._push(db: db, values: [sdata])
        })
    }
}
