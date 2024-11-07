//
//  DBTableDef.swift
//  SwiftSQLiteORM
//
//  Created by lalawue on 2024/11/6.
//

import Foundation

/// Table ORM mapping definition
public protocol DBTableDef {
    
    /// all table key names
    /// - DO NOT change key name already exist
    /// - after add keys (properties), increase schema version at the same time
    static var tableKeys: any DBTableKeys.Type { get }
    
    /// will create according to type
    /// - should be unique in all scope
    static var tableName: String { get }
    
    /// schema version for table keys, default 0
    /// - increase this number after you alter table keys (only support added)
    static var schemaVersion: Double { get }
    
    /// database file name
    static var databaseName: String { get }
}

extension DBTableDef {
    
    public static var tableName: String {
        return "orm_" + String(describing: Self.self) + "_t"
    }
    
    public static var schemaVersion: Double {
        return 0
    }
    
    public static var databaseName: String {
        return "orm_default.sqlite"
    }
}

/// Table ORM keys restriction
public protocol DBTableKeys: CodingKey, CaseIterable {
}
