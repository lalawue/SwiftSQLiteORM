//
//  DBTableDefHelper.swift
//  SwiftSQLiteORM
//
//  Created by lalawue on 2024/11/7.
//

import Runtime

private let _nameSet = Set<String>(["primaryKey", "tableName", "tableVersion", "databaseName"])
private let _infoCache = DBCache<TypeInfo>()

private let _p2cCache = DBCache<[String:String]>()
private let _c2pCache = DBCache<[String:String]>()

/// TableDef helper
extension DBTableDef {

    /// reserved property names
    static func _reservedNameSet() -> Set<String> {
        return _nameSet
    }
    
    /// get table definition properties
    static func _typeInfo() -> TypeInfo? {
        let tname = Self.tableName
        if let info = _infoCache[tname] {
            return info
        }
        if let info = try? typeInfo(of: Self.self) {
            _infoCache[tname] = info
            return info
        }
        return nil
    }

    /// get ORMKey property name mapping
    /// - property name -> column name
    /// - column name -> property name
    static func _nameMapping() -> (p2c:[String:String], c2p:[String:String]) {
        let tname = Self.tableName
        if let p2c = _p2cCache[tname], let c2p = _c2pCache[tname]  {
            return (p2c, c2p)
        } else {
            var p2c: [String:String] = [:]
            var c2p: [String:String] = [:]
            ORMKey.allCases.forEach {
                let pname = "\($0)"
                p2c[pname] = $0.rawValue
                c2p[$0.rawValue] = pname
            }
            _p2cCache[tname] = p2c
            _c2pCache[tname] = c2p
            return (p2c, c2p)
        }
    }
}
