//
//  DBTableDef.swift
//  SwiftSQLiteORM
//
//  Created by lii on 2024/11/6.
//

import Foundation

/// Table definition
public protocol DBTableDef {
    
    /// specify table name or created by engine
    static var tableName: String { get }
    
    /// specify database name or using default
    static var databaseName: String { get }
}

extension DBTableDef {
    
    public static var tableName: String {
        return ""
    }
    
    public static var databaseName: String {
        return "orm_default.sqlite"
    }
}
