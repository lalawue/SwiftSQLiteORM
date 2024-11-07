//
//  DBTableRecord.swift
//  SwiftSQLiteORM
//
//  Created by lalawue on 2024/11/6.
//

import GRDB
import Runtime

/// GRDB Record encode & decode, column names mapping
class DBTableRecord<T: DBTableDef>: Record {
    
    private(set) var row = Row()
    
    required init(row: Row) {
        self.row = row
        super.init(row: self.row)
    }
    
    /// create table with column names from T.tableKeys
    static func createTable(db: Database) throws {
        guard let pinfo = DBTableDefHelper.getInfo(T.self) else {
            return
        }
        let tset = Set(T.tableKeys.allKeyNames())
        try db.create(table: T.tableName, body: { tbl in
            pinfo.properties.forEach {
                if tset.contains($0.name) {
                    tbl.column($0.name, getColumnType(rawType: $0.type))
                }
            }
        })
    }

    /// alter table if T add column keys
    static func alterTable(db: Database) throws {
        // FIXME: to be continue
    }
    
    /// fetch GRDB rows then decode to [T]
    static func fetchAll(db: Database,
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

    /// push GRDB record after mapping Primitive value to database value
    /// - insert or update
    static func pushAll(db: Database, values: [T]) throws {
        try AnyEncoder.encode(values).map({ pvalue in
            var dict = [String:DatabaseValueConvertible?]()
            pvalue.keys.forEach {
                dict[$0] = pvalue[$0]?.toDatabaseValue() ?? NSNull()
            }
            return DBTableRecord<T>(row: Row(dict))
        }).forEach { try $0.save(db) }
    }
    
    /// execute raw sql
    static func executeRaw(db: Database, sql: String, arguments: StatementArguments? = nil) throws {
        try db.execute(sql: sql, arguments: arguments ?? StatementArguments())
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
