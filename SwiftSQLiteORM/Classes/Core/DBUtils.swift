//
//  DBLog.swift
//  SwiftSQLiteORM
//
//  Created by lalawue on 2024/11/6.
//

import GRDB

@inline(__always)
func dbLog(isError: Bool = false, _ text: String) {
    if isError {
        print("[SQLiteORM.Err] \(text)")
    } else {
#if DEBUG
        print("[SQLiteORM.Info] \(text)")
#endif
    }
}

extension DatabaseValueConvertible {
    
    func toPrimitive() -> Primitive {
        switch self {
        case let v as Bool:
            return v
        case let v as Int:
            return v
        case let v as Int8:
            return v
        case let v as Int16:
            return v
        case let v as Int32:
            return v
        case let v as Int64:
            return v
        case let v as UInt:
            return v
        case let v as UInt8:
            return v
        case let v as UInt16:
            return v
        case let v as UInt32:
            return v
        case let v as UInt64:
            return v
        case let v as Float:
            return v
        case let v as Double:
            return v
        case let v as String:
            return v
        case let v as Data:
            return v
        case let v as NSNumber:
            return v
        case let v as NSString:
            return v
        case let v as NSData:
            return v
        case let v as  CGFloat:
            return v
        default:
            return NSNull()
        }
    }
}



extension Primitive {
    
    func toDatabaseValue() -> DatabaseValueConvertible {
        switch self {
        case let v as Bool:
            return v
        case let v as Int:
            return v
        case let v as Int8:
            return v
        case let v as Int16:
            return v
        case let v as Int32:
            return v
        case let v as Int64:
            return v
        case let v as UInt:
            return v
        case let v as UInt8:
            return v
        case let v as UInt16:
            return v
        case let v as UInt32:
            return v
        case let v as UInt64:
            return v
        case let v as Float:
            return v
        case let v as Double:
            return v
        case let v as String:
            return v
        case let v as Data:
            return v
        case let v as NSNumber:
            return v
        case let v as NSString:
            return v
        case let v as NSData:
            return v
        case let v as  CGFloat:
            return v
        default:
            return NSNull()
        }
    }
}
