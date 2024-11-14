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
        case `in`(T.ORMKey, [Any])
                
        /// 'NOT'
        case not
        
        /// 'BETWEEN (_, _)'
        case between(key: T.ORMKey? = nil, Any, Any)
        
        /// 'ORDER BY'
        case orderBy(T.ORMKey, OrderBy? = nil)

        /// 'ORDER BY keys'
        case orderByKeys(_ krs: [(T.ORMKey, OrderBy?)])
        
        /// LIMIT
        case limit(Int)
        
        /// insert raw SQL string
        case _raw(String)

        /// insert ORMKey
        case _key([T.ORMKey])
    }
    
    public enum OrderBy: String {
        
        case ASC
        
        case DESC
    }
    
    static func sqlConditions(_ array: [Operator]) -> String {
        if array.isEmpty {
            return ""
        }
        var needWhere = false
        var needOrderBy = true
        var sql = ""
        array.forEach { op in
            switch op {
            case .eq(let key, let value):
                sql += " `\(key.rawValue)` = '\(_value(value))'"
                needWhere = true
            case .neq(let key, let value):
                sql += " `\(key.rawValue)` != '\(_value(value))'"
                needWhere = true
            case .gt(let key, let value):
                sql += " `\(key.rawValue)` > '\(_value(value))'"
                needWhere = true
            case .gte(let key, let value):
                sql += " `\(key.rawValue)` >= '\(_value(value))'"
                needWhere = true
            case .lt(let key, let value):
                sql += " `\(key.rawValue)` < '\(_value(value))'"
                needWhere = true
            case .lte(let key, let value):
                sql += " `\(key.rawValue)` <= '\(_value(value))'"
                needWhere = true
            case .like(let key, let value):
                sql += " `\(key)` LIKE '\(_value(value))'"
                needWhere = true
            case .in(let key, let values):
                sql += " `\(key.rawValue)` IN (\(values.map{"'\($0)'"}.joined(separator: ",")))"
                needWhere = true
            case .not:
                sql += " NOT"
            case .between(let key, let v1, let v2):
                if let k = key {
                    sql += " `\(k.rawValue)`"
                }
                sql += " BETWEEN '\(v1)' AND '\(v2)'"
                needWhere = true
            case .orderBy(let key, let seq):
                if needOrderBy {
                    needOrderBy = false
                    sql += " ORDER BY"
                }
                sql +=  " `\(key.rawValue)`"
                if let seq = seq {
                    sql += " \(seq.rawValue)"
                }
            case .orderByKeys(let krs):
                if krs.count > 0 {
                    if needOrderBy {
                        needOrderBy = true
                        sql += " ORDER BY"
                    }
                    krs.forEach { (key, seq) in
                        sql += " `\(key.rawValue)`"
                        if let seq = seq {
                            sql += " \(seq.rawValue)"
                        }
                    }
                }
            case .limit(let num):
                sql += " LIMIT \(num)"
            case ._raw(let str):
                sql += str
            case ._key(let keys):
                sql += " \(keys.map { "`\($0.rawValue)`"}.joined(separator: ","))"
                needWhere = true
            }
        }
        if needWhere {
            sql = " WHERE" + sql
        }
        return sql
    }
    
    private static func _value(_ value: Any) -> Any {
        switch value {
        case let v as Date:
            return v.databaseValue
        case let v as NSDate:
            return v.databaseValue
        default:
            return value
        }
    }
}
