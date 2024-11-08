//
//  DBRecordFilter.swift
//  SwiftSQLiteORM
//
//  Created by lalawue on 2024/11/8.
//

import Foundation

/// database CURD filter
public struct DBRecordFilter<T: DBTableDef> {
    
    /// some operator
    public enum Operator {
        
        /// '='
        case eq(T.ORMKey, Any)
        
        /// '!='
        case neq(T.ORMKey, Any)
        
        /// '>'
        case gt(T.ORMKey, Any)
        
        /// '>='
        case gte(T.ORMKey, Any)
        
        /// '<'
        case lt(T.ORMKey, Any)
        
        /// '<='
        case lte(T.ORMKey, Any)
        
        /// 'LIKE'
        case like(T.ORMKey, Any)
        
        /// 'IN'
        case `in`([Any])
        
        /// 'NOT'
        case not
        
        /// 'BETWEEN (_, _)'
        case between(Any, Any)
        
        /// 'GROUP BY (...) HAVING ...'
        case groupBy([T.ORMKey], _ having: String = "")
        
        /// 'ORDER BY []'
        case orderBy([T.ORMKey], OrderBy? = nil)
        
        /// LIMIT
        case limit(Int)
        
        /// insert raw SQL string
        case raw(String)
    }
    
    public enum OrderBy: String {
        
        case ASC
        
        case DESC
    }
    
    static func sqlConditions(_ array: [Operator]) -> String {
        if array.isEmpty {
            return ""
        }
        var sql = " WHERE"
        array.forEach { op in
            switch op {
            case .eq(let key, let value):
                sql += " `\(key.rawValue)` = '\(value)'"
            case .neq(let key, let value):
                sql += " `\(key.rawValue)` != '\(value)'"
            case .gt(let key, let value):
                sql += " `\(key.rawValue)` > '\(value)'"
            case .gte(let key, let value):
                sql += " `\(key.rawValue)` >= '\(value)'"
            case .lt(let key, let value):
                sql += " `\(key.rawValue)` < '\(value)'"
            case .lte(let key, let value):
                sql += " `\(key.rawValue)` <= '\(value)'"
            case .like(let key, let value):
                sql += " `\(key)` LIKE \(value)"
            case .in(let values):
                sql += " IN (\(values.map{"\($0)"}.joined(separator: ",")))"
            case .not:
                sql += " NOT"
            case .between(let v1, let v2):
                sql += " BETWEEN \(v1) AND \(v2)"
            case .groupBy(let keys, let having):
                sql += " GROUP BY \(keys.map{ "`\($0.rawValue)`" }.joined(separator: ","))"
                if !having.isEmpty {
                    sql += " HAVING \(having)"
                }
            case .orderBy(let keys, let seq):
                sql += " ORDER BY \(keys.map{ "`\($0.rawValue)`" }.joined(separator: ","))"
                if let seq = seq {
                    sql += " \(seq.rawValue)"
                }
            case .limit(let num):
                sql += " LIMIT \(num)"
            case .raw(let str):
                sql += str
            }
        }
        return sql
    }
}
