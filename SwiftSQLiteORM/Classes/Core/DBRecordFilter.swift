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
        case groupBy([T.ORMKey], _ having: String)
        
        /// 'ORDER BY []'
        case orderBy([T.ORMKey], OrderBy? = nil)
        
        /// LIMIT
        case limit(Int)
        
        /// insert raw SQL string
        case raw(String)
    }
    
    public enum OrderBy {
        
        case ASC
        
        case DESC
    }
    
    static func sqlConditions(_ array: [Operator]) -> String {
        return ""
    }
}
