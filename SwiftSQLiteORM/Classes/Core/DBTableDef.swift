//
//  DBTableDef.swift
//  SwiftSQLiteORM
//
//  Created by lalawue on 2024/11/6.
//

import Foundation

/// Table ORM mapping definition, manipulation interface
public protocol DBTableDef {
    
    /// table keys name
    /// - DO NOT change key name already exist
    /// - you can add keys (properties), increase schema version at the same time
    static var tableKeys: any DBTableKeys.Type { get }
    
    /// specify table name, or created by engine by default
    static var tableName: String { get }
    
    /// table schema version for table keys, default 0
    /// - increase when you add table keys
    static var tableVersion: Double { get }
    
    /// specify database name, or using default
    static var databaseName: String { get }
}

extension DBTableDef {
    
    /// if empty, will replace by definition mapping name
    public static var tableName: String {
        return ""
    }
    
    public static var tableVersion: Double {
        return 0
    }
    
    public static var databaseName: String {
        return "orm_default.sqlite"
    }
    
    static func reservedNameSet() -> Set<String> {
        return _reservedNameSet
    }
}

/// Table ORM keys restriction
public protocol DBTableKeys: RawRepresentable, CodingKey, CaseIterable {
}

fileprivate let _reservedNameSet = Set<String>(["tableKeys", "tableName", "tableVersion", "databaseName"])
