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
    let name: String

    /// table schema version
    let version: Double

    /// all column names
    let columns: [String]
    
    enum SchemaTableKeys: String, DBTableKey {
        case name
        case version
        case columns
    }

    static var tableKeys: ORMKey.Type {
        return SchemaTableKeys.self
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

/// record table name, schema version, all column names
class DBSchemaHelper {

    private var schemaCache = DBCache<DBSchemaTable>()

    private static let shared = DBSchemaHelper()

    private init() {
        let def = DBSchemaTable.self
        try? DBEngine.write(def, { db in
            try def._createTable(db: db)
        })
        do {
            guard let sdata = try Self.getSchema(def) else {
                try Self.setSchema(DBSchemaTable.self)
                return
            }
            if def.schemaVersion > sdata.version {
                try DBEngine.write(def, { db in
                    try def._alterTable(db: db, sdata: sdata)
                })
            }
        } catch {
            dbLog(isError: true, "failed to create schema table")
        }
    }

    /// get table schema from mem or from database
    static func getSchema<T: DBTableDef>(_ def: T.Type) throws -> DBSchemaTable? {
        let tname = def.tableName
        if let sdata = shared.schemaCache[tname] {
            return sdata
        }
        let sdef = DBSchemaTable.self
        let sql = "SELECT * FROM \(sdef.tableName) WHERE \(sdef.ORMKey.name) = ?"
        return try DBEngine.read(sdef, { db in
            return try sdef._fetch(db: db, sql: sql, arguments: [tname]).first
        })
    }

    /// set table schema to mem and database
    static func setSchema<T: DBTableDef>(_ def: T.Type) throws {
        let tname = def.tableName
        let sdata = DBSchemaTable(name: tname, version: def.schemaVersion, columns: def._allKeyNames())
        shared.schemaCache[tname] = sdata
        let sdef = DBSchemaTable.self
        try DBEngine.write(sdef, { db in
            try sdef._push(db: db, values: [sdata])
        })
    }
}
