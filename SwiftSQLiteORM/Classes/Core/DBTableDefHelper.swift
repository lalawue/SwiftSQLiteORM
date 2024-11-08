//
//  DBTableDefHelper.swift
//  SwiftSQLiteORM
//
//  Created by lalawue on 2024/11/7.
//

import Runtime

private let _nameSet = Set<String>(["primaryKey", "tableName", "tableVersion", "databaseName"])
private let _infoCache = DBCache<TypeInfo>()
private let _keyCache = DBCache<[String:String]>()

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

    /// get ORMKey property name -> raw text
    static func _allKeyMapping() -> [String:String] {
        let tname = Self.tableName
        if let v = _keyCache[tname] {
            return v
        } else {
            var dict: [String:String] = [:]
            ORMKey.allCases.forEach {
                dict["\($0)"] = $0.rawValue
            }
            _keyCache[tname] = dict
            return dict
        }
    }
}
