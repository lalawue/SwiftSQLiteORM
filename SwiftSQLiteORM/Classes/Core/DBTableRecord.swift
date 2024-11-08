//
//  DBTableRecord.swift
//  SwiftSQLiteORM
//
//  Created by lalawue on 2024/11/6.
//

import GRDB
import Runtime

extension DBTableDef {
    
    /// create table with column names from Self.tableKeys
    @inline(__always)
    static func _createTable(db: Database) throws {
        try DBTableRecord<Self>.createTable(db: db)
    }
    
    /// alter table for adding columns
    @inline(__always)
    static func _alterTable(db: Database, sdata: DBSchemaTable) throws {
        try DBTableRecord<Self>.alterTable(db: db, sdata: sdata)
    }
    
    /// fetch GRDB rows then decode to [T]
    @inline(__always)
    static func _fetch(db: Database,
                       sql: String,
                       arguments: StatementArguments? = nil) throws -> [Self]
    {
        try DBTableRecord<Self>.fetch(db: db, sql: sql, arguments: arguments)
    }
    
    /// push GRDB record after mapping Primitive value to database value
    /// - insert or update
    @inline(__always)
    static func _push(db: Database, values: [Self]) throws {
        try DBTableRecord<Self>.push(db: db, values: values)
    }

    /// delete GRDB record from value indicator
    @inline(__always)
    static func _delete(db: Database, values: [Self]) throws {
        try DBTableRecord<Self>.delete(db: db, values: values)
    }
    
    /// clear all entry in table
    @inline(__always)
    static func _clear(db: Database) throws {
        try db.drop(table: Self.tableName)
    }
}

/// GRDB Record encode & decode, column names mapping
private class DBTableRecord<T: DBTableDef>: Record {
    
   /// GRDB row data
    private(set) var row = Row()
    
    required init(row: Row) {
        self.row = row
        super.init(row: self.row)
    }
    
    static func createTable(db: Database) throws {
        guard let pinfo = T._typeInfo() else {
            throw DatabaseError(resultCode: .SQLITE_INTERNAL)
        }
        let p2c = T._nameMapping().p2c
        var cpname = ""
        if let pname = T.primaryKey, let cname = p2c["\(pname)"] {
            cpname = cname
        }
        do {
            try db.create(table: T.tableName, ifNotExists: true, body: { tbl in
                pinfo.properties.forEach { p in
                    guard let cname = p2c[p.name] else {
                        return
                    }
                    let col = tbl.column(cname, getColumnType(rawType: p.type))
                    if cname == cpname {
                        col.primaryKey(onConflict: .abort)
                    }
                    if let _ = p.type as? ExpressibleByNilLiteral {
                        // nullable
                    } else {
                        col.notNull(onConflict: .abort)
                    }
                }
                if cpname.isEmpty {
                    tbl.column("rowid", .integer).primaryKey(onConflict: .abort, autoincrement: true)
                }
            })
        } catch {
            dbLog("create table error: \(error.localizedDescription), \(T.tableName) \(T.databaseName)")
        }
    }
    
    static func alterTable(db: Database, sdata: DBSchemaTable) throws {
        guard T.tableVersion > sdata.tversion else {
            return
        }
        let p2c = T._nameMapping().p2c
        let oset = Set(sdata.tcolumns)
        let newColumns = p2c.compactMap({ oset.contains($0.key) ? nil : $0.value })
        guard newColumns.count > 0 else {
            return
        }
        let nset = Set(newColumns)
        try db.alter(table: T.tableName, body: { tbl in
            guard let pinfo = T._typeInfo() else {
                return
            }
            pinfo.properties.forEach {
                if let cname = p2c[$0.name], nset.contains($0.name) {
                    tbl.add(column: cname, getColumnType(rawType: $0.type))
                }
            }
        })
    }
    
    static func fetch(db: Database,
                      sql: String,
                      arguments: StatementArguments? = nil) throws -> [T]
    {
        guard let records = try? fetchAll(db, sql: sql, arguments: arguments ?? StatementArguments()) as? [Self],
              records.count > 0 else
        {
            return []
        }
        let c2p = T._nameMapping().c2p
        let containers = records.map({
            let r = $0.row
            var dict = [String:Primitive]()
            r.columnNames.forEach { cname in
                if let pname = c2p[cname] {
                    dict[pname] = r[cname]?.toPrimitive() ?? NSNull()
                }
            }
            return dict
        })
        return try AnyDecoder.decode(T.self, from: containers)
    }

    static func push(db: Database, values: [T]) throws {
        let p2c = T._nameMapping().p2c
        try AnyEncoder.encode(values).map({ value in
            var dict = [String:DatabaseValueConvertible?]()
            value.forEach { p in
                if let cname = p2c[p.key] {
                    dict[cname] = value[p.key]?.toDatabaseValue() ?? NSNull()
                }
            }
            return DBTableRecord<T>(row: Row(dict))
        }).forEach { try $0.save(db) }
    }
    
    static func delete(db: Database, values: [T]) throws {
        let p2c = T._nameMapping().p2c
        var array = AnyEncoder.encode(values).map({ pvalue in
            var dict = [String:DatabaseValueConvertible?]()
            pvalue.forEach { p in
                if let cname = p2c[p.key] {
                    dict[cname] = pvalue[p.key]?.toDatabaseValue() ?? NSNull()
                }
            }
            return DBTableRecord<T>(row: Row(dict))
        })
        while let record = array.popLast() {
            try record.delete(db)
        }
    }
        
    /// raw to container
    override func encode(to container: inout PersistenceContainer) {
        let r = self.row
        r.columnNames.forEach { cname in
            container[cname] = r[cname]
        }
    }
    
    override class var databaseTableName: String {
        return T.tableName
    }
}
