//
//  DBLog.swift
//  SwiftSQLiteORM
//
//  Created by lalawue on 2024/11/6.
//

import GRDB

@inlinable
func dbLog(isError: Bool = false, _ text: String) {
    if isError {
        print("[SQLiteORM.Err] \(text)")
    } else {
#if DEBUG
        print("[SQLiteORM.Info] \(text)")
#endif
    }
}

fileprivate let _nameSet = Set<String>(["tableName", "schemaVersion", "databaseName"])

extension DBTableDef {
    
    @inline(__always)
    static func _reservedNameSet() -> Set<String> {
        return _nameSet
    }
    
    @inline(__always)
    static func _allKeyNames() -> [String] {
        return ORMKey.allCases.map({ $0.rawValue })
    }
}

func getColumnType(rawType: Any.Type) -> Database.ColumnType {
    switch rawType {
    case is Bool.Type:
        return .boolean
    case is any BinaryInteger.Type:
        return .integer
    case is any BinaryFloatingPoint.Type:
        return .double
    case is String.Type: fallthrough
    case is NSString.Type:
        return .text
    case is Date.Type: fallthrough
    case is NSDate.Type:
        return .datetime
    case is Data.Type: fallthrough
    case is NSData.Type: fallthrough
    default:
        return .blob
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
