//
//  DBTableDef.swift
//  SwiftSQLiteORM
//
//  Created by lalawue on 2024/11/6.
//

import Foundation

/// Table ORM mapping definition
public protocol DBTableDef {
    
    /// associate all key names
    /// - DO NOT change mapping name already exist
    /// - after add properties, increase schema version at the same time
    associatedtype ORMKey: DBTableKey
    
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

/// Table ORM column name
public protocol DBTableKey: RawRepresentable, CaseIterable where RawValue == String {
    
}
