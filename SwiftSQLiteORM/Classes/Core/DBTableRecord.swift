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
        try db.execute(sql: "DELETE FROM \(Self.tableName)")
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
        guard let pinfo = DBTableDefHelper.getInfo(T.self) else {
            return
        }
        let tset = Set(T._allKeyNames())
        try db.create(table: T.tableName, ifNotExists: true, body: { tbl in
            pinfo.properties.forEach {
                if tset.contains($0.name) {
                    tbl.column($0.name, getColumnType(rawType: $0.type))
                }
            }
        })
    }
    
    static func alterTable(db: Database, sdata: DBSchemaTable) throws {
        guard T.schemaVersion > sdata.version else {
            return
        }
        let oset = Set(sdata.columns)
        let newColumns = T._allKeyNames().filter({ !oset.contains($0) })
        guard newColumns.count > 0 else {
            return
        }
        let nset = Set(newColumns)
        try db.alter(table: T.tableName, body: { tbl in
            guard let pinfo = DBTableDefHelper.getInfo(T.self) else {
                return
            }
            pinfo.properties.forEach {
                if nset.contains($0.name) {
                    tbl.add(column: $0.name, getColumnType(rawType: $0.type))
                }
            }
        })
    }
    
    static func fetch(db: Database,
                      sql: String,
                      arguments: StatementArguments? = nil) throws -> [T]
    {
        guard let records = try? super.fetchAll(db, sql: sql, arguments: arguments ?? StatementArguments()) as? [Self] else {
            return []
        }
        let containers = records.map({
            let r = $0.row
            var dict = [String:Primitive]()
            r.columnNames.forEach {
                dict[$0] = r[$0]?.toPrimitive() ?? NSNull()
            }
            return dict
        })
        return try AnyDecoder.decode(T.self, from: containers)
    }

    static func push(db: Database, values: [T]) throws {
        try AnyEncoder.encode(values).map({ pvalue in
            var dict = [String:DatabaseValueConvertible?]()
            pvalue.keys.forEach {
                dict[$0] = pvalue[$0]?.toDatabaseValue() ?? NSNull()
            }
            return DBTableRecord<T>(row: Row(dict))
        }).forEach { try $0.save(db) }
    }
    
    static func delete(db: Database, values: [T]) throws {
        var array = AnyEncoder.encode(values).map({ pvalue in
            var dict = [String:DatabaseValueConvertible?]()
            pvalue.keys.forEach {
                dict[$0] = pvalue[$0]?.toDatabaseValue() ?? NSNull()
            }
            return DBTableRecord<T>(row: Row(dict))
        })
        while var record = array.popLast() {
            try record.delete(db)
        }
    }
        
    /// raw to container
    override func encode(to container: inout PersistenceContainer) {
        let r = self.row
        r.columnNames.forEach {
            container[$0] = r[$0]
        }
    }
    
    override class var databaseTableName: String {
        return T.tableName
    }
}
