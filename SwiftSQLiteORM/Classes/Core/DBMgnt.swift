//
//  DBWrapper.swift
//  SwiftSQLiteORM
//
//  Created by lalawue on 2024/11/6.
//

import GRDB

/// database management interface
final public class DBMgnt {

    /// record whether table was checked
    private let flagCache = DBCache<Bool>()
    
    private static let shared = DBMgnt()
    
    private init() {
    }
    
    /// create or alter table if needed
    static func checkTable<T: DBTableDef>(_ def: T.Type) throws {
        let tname = def.tableName
        
        if let _ = shared.flagCache[tname] {
            return
        }
        shared.flagCache[tname] = true
        
        // if def's schema table entry not exist, create it first
        guard let sdata = try DBSchemaHelper.getSchema(def) else {
            try DBEngine.write(def, { db in
                try def._createTable(db: db)
            })
            try DBSchemaHelper.setSchema(def)
            return
        }
        
        // if def's schema version increased
        guard def.schemaVersion > sdata.version else {
            return
        }

        try DBEngine.write(def, { db in
            try def._alterTable(db: db, sdata: sdata)
        })
        try DBSchemaHelper.setSchema(def)
    }
    
    public static func fetch<T: DBTableDef>(_ def: T.Type) throws -> [T] {
        return []
    }
    
    public static func push<T: DBTableDef>(_ values: [T]) throws {
        let def = T.self
        try DBEngine.write(def, {
            try def._push(db: $0, values: values)
        })
    }
    
    public static func delete<T: DBTableDef>(_ values: [T]) throws {
        let def = T.self
        try DBEngine.write(def, {
            try def._clear(db: $0)
        })
    }
    
    public static func clear<T: DBTableDef>(_ def: T.Type) throws {
        try DBEngine.write(def, {
            try def._clear(db: $0)
        })
    }
}
