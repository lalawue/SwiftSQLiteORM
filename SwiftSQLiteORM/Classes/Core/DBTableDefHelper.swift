//
//  DBTableDefHelper.swift
//  SwiftSQLiteORM
//
//  Created by lalawue on 2024/11/7.
//

import Runtime

private let _nameSet = Set<String>(["primaryKey", "tableName", "tableVersion", "databaseName"])

/// TableDef helper
extension DBTableDef {

    /// reserved property names
    static func _reservedNameSet() -> Set<String> {
        return _nameSet
    }
    
    /// get table definition properties
    @inline(__always)
    static func _typeInfo() throws -> TypeInfo {
        do {
            return try rtTypeInfo(of: Self.self)
        } catch {
            throw DBORMError.FailedToGetTypeInfo(typeName: "\(Self.self)")
        }
    }

    /// get ORMKey property name mapping
    /// - property name -> column name
    @inline(__always)
    static func _nameMapping() -> [String:String] {
        return ormNameMapping(Self.self)
    }
}
