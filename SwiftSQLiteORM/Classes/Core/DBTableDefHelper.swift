//
//  DBTableDefHelper.swift
//  SwiftSQLiteORM
//
//  Created by lalawue on 2024/11/7.
//

import Runtime

private let _nameSet = Set<String>(["primaryKey", "tableName", "tableVersion", "databaseName"])

private let _p2cCache = DBCache<[String:String]>()

/// TableDef helper
extension DBTableDef {

    /// reserved property names
    static func _reservedNameSet() -> Set<String> {
        return _nameSet
    }
    
    /// get table definition properties
    @inline(__always)
    static func _typeInfo() -> TypeInfo? {
        return try? rtTypeInfo(of: Self.self)
    }

    /// get ORMKey property name mapping
    /// - property name -> column name
    static func _nameMapping() -> [String:String] {
        let tname = Self.tableName
        if let p2c = _p2cCache[tname]  {
            return p2c
        } else {
            var p2c: [String:String] = [:]
            ORMKey.allCases.forEach {
                p2c["\($0)"] = $0.rawValue
            }
            _p2cCache[tname] = p2c
            return p2c
        }
    }
}
