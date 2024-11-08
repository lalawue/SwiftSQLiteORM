//
//  DBWrapper.swift
//  SwiftSQLiteORM
//
//  Created by lalawue on 2024/11/6.
//

import GRDB

class DBValue: FetchableRecord, PersistableRecord {
    
    var row: Row
    
    required init(row: GRDB.Row) {
        self.row = row
    }
    
    func encode(to container: inout GRDB.PersistenceContainer) {
        container["name"] = row["name"]
        container["index"] = row["index"]
    }
    
    static var databaseTableName: String {
        return "orm_abc_t"
    }
}

/// database management interface
final public class DBMgnt {
    
    public static func fetch<T: DBTableDef>(_ def: T.Type) throws -> [T] {
        do {
            return try shared._fetch(def)
        } catch {
            dbLog("fetch \(T.tableName) \(T.databaseName) failed: \(error.localizedDescription)")
            return []
        }
    }
    
    public static func push<T: DBTableDef>(_ values: [T]) throws {
        do {
            dbLog("try push \(T.tableName) \(T.databaseName)")
            try shared._push(values)
        } catch {
            dbLog("push \(T.tableName) \(T.databaseName) failed: \(error.localizedDescription)")
        }
    }
    
    public static func delete<T: DBTableDef>(_ values: [T]) throws {
        try shared._delete(values)
    }
    
    public static func clear<T: DBTableDef>(_ def: T.Type) throws {
        try shared._clear(def)
    }
    
    // MARK: -
    
    private static let shared = DBMgnt()
    
    private init() {
        try? Self._checkTable(DBSchemaTable.self)
    }
    
    private func _fetch<T: DBTableDef>(_ def: T.Type) throws -> [T] {
        try Self._checkTable(def)
        let _ = try DBEngine.read(def, { db in
            if let row = try Row.fetchAll(db, sql: "SELECT * FROM '\(T.tableName)'").first {
                let value = DBValue(row: row)
                dbLog("fetch value: \(value.row["name"]) \(value.row["index"])")
            }
            return []
        })
        return []
//        return try DBEngine.read(def, {
//            try T._fetch(db: $0, sql: "SELECT * FROM '\(def.tableName)'")
//        })
    }
    
    private func _push<T: DBTableDef>(_ values: [T]) throws {
        try Self._checkTable(T.self)
        try DBEngine.write(T.self, {
            try T._push(db: $0, values: values)
            dbLog("push save success \(T.tableName) in \(T.databaseName)")
        })
    }
    
    private func _delete<T: DBTableDef>(_ values: [T]) throws {
        try Self._checkTable(T.self)
        try DBEngine.write(T.self, {
            try T._clear(db: $0)
        })
    }
    
    private func _clear<T: DBTableDef>(_ def: T.Type) throws {
        try Self._checkTable(def)
        try DBEngine.write(def, {
            try def._clear(db: $0)
        })
    }
    
    /// record whether table was checked
    private static let _flagCache = DBCache<Bool>()
    
    /// create or alter table if needed
    private static func _checkTable<T: DBTableDef>(_ def: T.Type) throws {
        let tname = def.tableName
        
        if let _ = _flagCache[tname] {
            return
        }
        _flagCache[tname] = true
        
        defer {
            dbLog("DBMgnt check table done for \(T.tableName), \(T.databaseName)")
        }
        
        // if def's schema table entry not exist, create it first
        guard let sdata = try DBSchemaHelper.getSchema(def) else {
            try DBEngine.write(def, { db in
                try def._createTable(db: db)
            })
            try DBSchemaHelper.setSchema(def)
            return
        }
        
        // if def's schema version increased
        guard def.tableVersion > sdata.tversion else {
            return
        }

        try DBEngine.write(def, { db in
            try def._alterTable(db: db, sdata: sdata)
        })
        try DBSchemaHelper.setSchema(def)
    }
}
