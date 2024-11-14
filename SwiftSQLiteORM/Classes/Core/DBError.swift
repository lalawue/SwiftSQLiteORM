//
//  DBError.swift
//  SwiftSQLiteORM
//
//  Created by lalawue on 2024/11/9.
//

import Foundation

/// database orm error
public enum DBORMError: Error {
    
    case FailedToCreateDBQueue
    
    case FailedToGetTypeInfo

    case FailedToOperateWithoutPrimaryKey
    
    case FailedToOperateWithProperty(tname: String, pname: String, errmsg: String)
}
