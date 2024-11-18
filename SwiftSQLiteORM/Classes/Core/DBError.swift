//
//  DBError.swift
//  SwiftSQLiteORM
//
//  Created by lalawue on 2024/11/9.
//

import Foundation

/// database orm error
public enum DBORMError: Error {
    
    /// failed to get cipher passwd for GRDB
    case FailedToGetCipherPasswd(dbPath: String)

    /// failed to initialize database operation queue
    case FailedToCreateDBQueue(dbPath: String, error: Error)
    
    /// can't get type info from Runtime
    case FailedToGetTypeInfo(typeName: String)

    /// operation require primaryKey
    case FailedToOperateWithoutPrimaryKey(typeName: String)
    
    /// property failed to encode to database
    case FailedToEncodeProperty(typeName: String, propertyName: String)

    /// property afiled to decode from database
    case FailedToDecodeProperty(typeName: String, propertyName: String)
}

extension DBORMError {
    public var localizedDescription: String {
        switch self {
        case .FailedToGetCipherPasswd(let dbPath):
            return "FailedToGetCipherPasswd for '\(dbPath)'"
        case .FailedToCreateDBQueue(let dbPath, let error):
            return "FailedToCreateDBQueue in '\(dbPath)', underlying error: \(error.localizedDescription)"
        case .FailedToGetTypeInfo(let typeName):
            return "FailedToGetTypeInfo for '\(typeName)'"
        case .FailedToOperateWithoutPrimaryKey(let typeName):
            return "FailedToOperateWithoutPrimaryKey for '\(typeName)'"
        case .FailedToEncodeProperty(let typeName, let propertyName):
            return "FailedToEncodeProperty for '\(typeName) -> \(propertyName)'"
        case .FailedToDecodeProperty(let typeName, let propertyName):
            return "FailedToDecodeProperty for '\(typeName) -> \(propertyName)'"
        }
    }
}
