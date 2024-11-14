//
//  DBWrapper.swift
//  SwiftSQLiteORM
//
//  Created by lalawue on 2024/11/6.
//

import GRDB

/// ORM Database Management Interface
final public class DBMgnt {

    /// database path
    public var databasePath: String {
        return DBEngine.databasePath
    }
    
    /// fetch [T] with filter
    public static func fetch<T: DBTableDef>(_ def: T.Type, _ filters: DBRecordFilter<T>.Operator...) throws -> [T] {
        return try shared._fetch(def, Array(filters))
    }
    
    /// insert / update database with [T]
    public static func push<T: DBTableDef>(_ values: [T]) throws {
        try shared._push(values)
    }
    
    /// delete entries with [T], require PrimaryKey
    public static func deletes<T: DBTableDef>(_ values: [T]) throws {
        try shared._deletes(values)
    }
    
    /// delete entries with filter
    public static func delete<T: DBTableDef>(_ def: T.Type, _ filters: DBRecordFilter<T>.Operator...) throws {
        try shared._delete(def, Array(filters))
    }
    
    /// delete all entries
    public static func clear<T: DBTableDef>(_ def: T.Type) throws {
        try shared._clear(def)
    }
    
    /// drop table
    public static func drop<T: DBTableDef>(_ def: T.Type) throws {
        try shared._drop(def)
    }
    
    // MARK: -
    
    private static let shared = DBMgnt()
    
    private init() {
        try? Self._checkTable(DBSchemaTable.self)
    }
    
    private func _fetch<T: DBTableDef>(_ def: T.Type, _ options: [DBRecordFilter<T>.Operator]) throws -> [T] {
        try Self._checkTable(def)
        return try DBEngine.read(def, {
            return try def._fetch(db: $0, options: options)
        })
    }
    
    private func _push<T: DBTableDef>(_ values: [T]) throws {
        if values.isEmpty {
            return
        }
        try Self._checkTable(T.self)
        try DBEngine.write(T.self, {
            try T._push(db: $0, values: values)
        })
    }
    
    private func _deletes<T: DBTableDef>(_ values: [T]) throws {
        if values.isEmpty {
            return
        }
        guard let _ = T.primaryKey else {
            throw DBORMError.FailedToOperateWithoutPrimaryKey
        }
        try Self._checkTable(T.self)
        try DBEngine.write(T.self, {
            try T._deletes(db: $0, values: values)
        })
    }
    
    private func _delete<T: DBTableDef>(_ def: T.Type, _ options: [DBRecordFilter<T>.Operator]) throws {
        if options.isEmpty {
            return
        }
        try Self._checkTable(def)
        try DBEngine.write(def, {
            try def._delete(db: $0, options: options)
        })
    }
    
    private func _clear<T: DBTableDef>(_ def: T.Type) throws {
        try Self._checkTable(def)
        try DBEngine.write(def, {
            try def._clear(db: $0)
        })
    }
    
    private func _drop<T: DBTableDef>(_ def: T.Type) throws {
        try DBSchemaHelper.dropSchema(def)
        Self._flagCache["\(def)"] = nil
        try DBEngine.write(def, {
            try def._drop(db: $0)
        })
        rtTypeClear(of: def)
        ormNameMappingClear(def)
    }
    
    /// record whether table was checked
    private static let _flagCache = DBCache<Bool>()
    
    /// create or alter table if needed
    private static func _checkTable<T: DBTableDef>(_ def: T.Type) throws {
        let tname = "\(def)" // trick it for table name
        if let _ = _flagCache[tname] {
            return
        }
        _flagCache[tname] = true
        
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
