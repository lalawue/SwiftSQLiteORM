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
    static func _fetch(db: Database, options: [DBRecordFilter<Self>.Operator]) throws -> [Self] {
        let sql = "SELECT * FROM `\(Self.tableName)`" + DBRecordFilter<Self>.sqlConditions(options)
        return try DBTableRecord<Self>.fetch(db: db, sql: sql)
    }
    
    /// push GRDB record after mapping Primitive value to database value
    /// - insert or update
    @inline(__always)
    static func _push(db: Database, values: [Self]) throws {
        try DBTableRecord<Self>.push(db: db, values: values)
    }

    /// delete GRDB record from value indicator
    @inline(__always)
    static func _deletes(db: Database, values: [Self]) throws {
        let primaryValues = values.compactMap({ AnyEncoder.reflectPrimaryValue($0) })
        try DBTableRecord<Self>.deletes(db: db, primaryValues: primaryValues)
    }
    
    /// delete GRDB record from option filter
    @inline(__always)
    static func _delete(db: Database, options: [DBRecordFilter<Self>.Operator]) throws {
        try db.execute(sql: "DELETE FROM `\(Self.tableName)`" + DBRecordFilter<Self>.sqlConditions(options))
    }

    /// drop table
    @inline(__always)
    static func _drop(db: Database) throws {
        try db.execute(sql: "DROP TABLE `\(Self.tableName)`")
    }
}

private let _emptyRow = Row()
private let _emptyPVs = [String:Primitive]()
private let _emptyArgs = StatementArguments()

/// GRDB Record encode & decode, column names mapping
private class DBTableRecord<T: DBTableDef>: Record {

    /// instance from fetch operation
    private let _obj: T?
    
    /// property name -> value from push / delete operation
    private let _pvs: [String:Primitive]
    
    required init(row: Row, pvs: [String:Primitive]) {
        if row == _emptyRow {
            self._obj = nil
        } else {
            self._obj = try? AnyDecoder.decode(T.self, T._nameMapping(), from: row)
        }
        self._pvs = pvs
        super.init(row: row)
    }
    
    required convenience init(row: Row) {
        self.init(row: row, pvs: _emptyPVs)
    }
    
    static func createTable(db: Database) throws {
        guard let pinfo = T._typeInfo() else {
            throw DBORMError.FailedToGetTypeInfo
        }
        let p2c = T._nameMapping()
        var cpname = ""
        if let pname = T.primaryKey, let cname = p2c["\(pname)"] {
            cpname = cname
        }
        try db.create(table: T.tableName, ifNotExists: true, body: { tbl in
            pinfo.properties.forEach { p in
                guard let cname = p2c[p.name] else {
                    return
                }
                let col = tbl.column(cname, getColumnType(rawType: p.type))
                if cname == cpname {
                    col.primaryKey(onConflict: .abort)
                }
                if let _ = p.type as? ExpressibleByNilLiteral.Type {
                    // nullable
                } else {
                    col.notNull(onConflict: .abort)
                }
                //dbLog("create column '\(cname)' with '\(getColumnType(rawType: p.type))'")
            }
            if cpname.isEmpty {
                tbl.column("rowid", .integer).primaryKey(onConflict: .abort, autoincrement: true)
                //dbLog("create column 'rowid'")
            }
        })
    }
    
    static func alterTable(db: Database, sdata: DBSchemaTable) throws {
        guard T.tableVersion > sdata.tversion else {
            return
        }
        let p2c = T._nameMapping()
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
            pinfo.properties.forEach { p in
                guard let cname = p2c[p.name], nset.contains(p.name) else {
                    return
                }
                let col = tbl.add(column: cname, getColumnType(rawType: p.type))
                if let val = (try? defaultValue(of: p.type)) as? DatabaseValueConvertible {
                    col.defaults(to: val)
                } else {
                    col.defaults(to: NSNull())
                }
                //dbLog("add column '\(cname)'")
            }
        })
    }
    
    /// fetch row to instance
    static func fetch(db: Database, sql: String) throws -> [T] {
        //dbLog("(\(T.databaseName)) fetch sql: '\(sql)'")
        guard let arr = try? fetchAll(db, sql: sql, arguments: _emptyArgs) as? [Self], arr.count > 0 else {
            return []
        }
        return arr.compactMap({ $0._obj })
    }

    /// transform to record then insert / update
    static func push(db: Database, values: [T]) throws {
        let p2c = T._nameMapping()
        try values.compactMap { vt -> DBTableRecord<T>? in
            guard var info = T._typeInfo() else {
                return nil
            }
            let genericType: Any.Type
            if info.kind == .optional {
                guard info.genericTypes.count == 1 else {
                    return nil
                }
                genericType = info.genericTypes.first!
                info = try rtTypeInfo(of: genericType)
            } else {
                genericType = info.type
            }
            info = try rtTypeInfo(of: genericType)
            //
            var pvs = [String:Primitive]()
            try info.properties.forEach { vp in
                guard let _ = p2c[vp.name] else {
                    return
                }
                let v = try vp.get(from: vt)
                if let v1 = try getValue(v) {
                    pvs[vp.name] = v1
                }
            }
            return DBTableRecord<T>(row: _emptyRow, pvs: pvs)
        }.forEach {
            try $0.performSave(db)
        }
        
//        try AnyEncoder.encode(pcmap: T._nameMapping(), values).map({
//            DBTableRecord<T>(row: _emptyRow, pvs: $0)
//        }).forEach { try $0.performSave(db) }
    }
    
    private static func getValue(_ v: Any) throws -> Primitive? {
        switch v {
        case let v1 as Primitive:
            if let v1 = v1 as? UInt64 {
                return Int64(bitPattern: v1)
            } else {
                return v1
            }
        case let v1 as Optional<Any>:
            switch v1 {
            case .none:
                return nil
            case .some(let v2):
                switch v2 {
                case let v3 as Primitive:
                    if let v3 = v3 as? UInt64 {
                        return Int64(bitPattern: v3)
                    } else {
                        return v3
                    }
                default:
                    do {
                        if let v2 = v2 as? Codable {
                            let data = try JSONEncoder().encode(v2)
                            return String(bytes: data.bytes)
                        } else {
                            return nil
                        }
                    } catch {
                        throw DBORMError.FailedToOperateWithProperty(tname: "\(v2)", pname: "name", errmsg: error.localizedDescription)
                    }
                }
            }
        default:
            do {
                if let v = v as? Codable {
                    let data = try JSONEncoder().encode(v)
                    return String(bytes: data.bytes)
                } else {
                    return nil
                }
            } catch {
                throw DBORMError.FailedToOperateWithProperty(tname: "\(v)", pname: "name", errmsg: error.localizedDescription)
            }
        }
    }

    /// delete record with Primary Key -> Value
    static func deletes(db: Database, primaryValues: [Any]) throws {
        let sql = "DELETE FROM `\(T.tableName)`" + DBRecordFilter<T>.sqlConditions([.in(T.primaryKey!, primaryValues)])
        try db.execute(sql: sql)
    }
        
    /// insert / update
    override func encode(to container: inout PersistenceContainer) {
        T._nameMapping().forEach { (pname, cname) in
            container[cname] = _pvs[pname]
        }
    }
    
    override class var databaseTableName: String {
        return T.tableName
    }
}
