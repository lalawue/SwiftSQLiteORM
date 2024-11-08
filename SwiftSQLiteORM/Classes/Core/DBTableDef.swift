//
//  DBTableDef.swift
//  SwiftSQLiteORM
//
//  Created by lalawue on 2024/11/6.
//

import Foundation

/// Table ORM mapping definition
public protocol DBTableDef {
    
    /// associate all propety name -> column name
    /// - DO NOT delete / change column name already created
    /// - support add columns
    associatedtype ORMKey: DBTableKey

    /// specify primary key, or using hidden rowID
    static var primaryKey: ORMKey? { get }
    
    /// specify table name or use type name
    /// - should be unique in all scope
    static var tableName: String { get }
    
    /// schema version for table columns, default 0
    /// - increase this number after you add columns
    static var tableVersion: Double { get }
    
    /// specify database file name or use default
    static var databaseName: String { get }

    /// update  instance property value created by type reflection
    /// - only ORMKey covered property can restore value from database column
    /// - others property will use default value
    static func ormUpdateNew(_ value: inout Self) -> Self
}

extension DBTableDef {
    
    public static var primaryKey: ORMKey? {
        return nil
    }
    
    public static var tableName: String {
        return "orm_" + String(describing: Self.self) + "_t"
    }
    
    public static var tableVersion: Double {
        return 0
    }
    
    public static var databaseName: String {
        return "orm_default.sqlite"
    }
    
    public static func ormUpdateNew(_ value: inout Self) -> Self {
        return value
    }
}

/// Table ORM column name
public protocol DBTableKey: RawRepresentable<String>, CaseIterable {
    
}
