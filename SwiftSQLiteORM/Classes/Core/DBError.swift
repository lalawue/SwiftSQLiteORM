//
//  DBError.swift
//  SwiftSQLiteORM
//
//  Created by lii on 2024/11/9.
//

import Foundation

/// database orm error
public enum DBORMError: Error {
    
    case FailedToCreateDBQueue
    
    case FailedToGetTypeInfo

    case OnlySupportWithPrimaryKey
}
