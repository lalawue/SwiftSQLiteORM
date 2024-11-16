//
//  DBPrimitive.swift
//  SwiftSQLiteORM
//
//  Created by lalawue on 2024/11/16.
//

import Foundation

/// database column type
public enum DBStoreType {
    
    /// Int64
    case INTEGER
    
    /// Double
    case REAL
    
    /// String
    case TEXT

    /// Data
    case BLOB
}

/// database store value type
public enum DBStoreValue {
    
    /// box within int64
    case integer(Int64)

    /// box within double
    case real(Double)

    /// box within String
    case text(String)

    /// box within data
    case blob(Data)
}

/// supported protocol for store / restrore from database
public protocol DBPrimitive {

    /// database column type
    static var ormStoreType: DBStoreType {  get }

    /// mapping value to store in database
    static func ormToStoreValue(_ value: Self) -> DBStoreValue?

    /// restore value from database
    static func ormFromStoreValue(_ value: DBStoreValue) -> Self?
}

// MARK: - Bool

extension Bool: DBPrimitive {
    
    public static var ormStoreType: DBStoreType {
        .INTEGER
    }
    
    public static func ormToStoreValue(_ value: Bool) -> DBStoreValue? {
        return .integer(Int64(value ? 1 : 0))
    }
    
    public static func ormFromStoreValue(_ value: DBStoreValue) -> Bool? {
        if case .integer(let int64) = value {
            return (int64 == 1)
        }
        return nil
    }
}

// MARK: - Int64

extension BinaryInteger {
    
    @inline(__always)
    static func _ormToStoreValue(_ value: any BinaryInteger) -> DBStoreValue? {
        return .integer(Int64(exactly: value)!)
    }

    @inline(__always)
    static func _ormFromStoreValue(_ value: DBStoreValue) -> Self? {
        if case .integer(let int64) = value {
            return Self(exactly: int64)
        }
        return nil
    }
}

extension Int: DBPrimitive {
    public static var ormStoreType: DBStoreType { .INTEGER }
    public static func ormToStoreValue(_ value: Int) -> DBStoreValue? {
        _ormToStoreValue(value)
    }
    public static func ormFromStoreValue(_ value: DBStoreValue) -> Int? {
        _ormFromStoreValue(value)
    }
}

extension Int8: DBPrimitive {
    public static var ormStoreType: DBStoreType { .INTEGER }
    public static func ormToStoreValue(_ value: Int8) -> DBStoreValue? {
        _ormToStoreValue(value)
    }
    public static func ormFromStoreValue(_ value: DBStoreValue) -> Int8? {
        _ormFromStoreValue(value)
    }
}

extension Int16: DBPrimitive {
    public static var ormStoreType: DBStoreType { .INTEGER }
    public static func ormToStoreValue(_ value: Int16) -> DBStoreValue? {
        _ormToStoreValue(value)
    }
    public static func ormFromStoreValue(_ value: DBStoreValue) -> Int16? {
        _ormFromStoreValue(value)
    }
}

extension Int32: DBPrimitive {
    public static var ormStoreType: DBStoreType { .INTEGER }
    public static func ormToStoreValue(_ value: Int32) -> DBStoreValue? {
        _ormToStoreValue(value)
    }
    public static func ormFromStoreValue(_ value: DBStoreValue) -> Int32? {
        _ormFromStoreValue(value)
    }
}

extension Int64: DBPrimitive {
    public static var ormStoreType: DBStoreType { .INTEGER }
    public static func ormToStoreValue(_ value: Int64) -> DBStoreValue? {
        return .integer(value)
    }
    public static func ormFromStoreValue(_ value: DBStoreValue) -> Int64? {
        if case .integer(let int64) = value {
            return int64
        }
        return nil
    }
}

// MARK: UInt64

extension UInt: DBPrimitive {
    public static var ormStoreType: DBStoreType { .INTEGER }
    public static func ormToStoreValue(_ value: UInt) -> DBStoreValue? {
        UInt64.ormToStoreValue(UInt64(value))
    }
    public static func ormFromStoreValue(_ value: DBStoreValue) -> UInt? {
        if let uval = UInt64.ormFromStoreValue(value) {
            return UInt(exactly: uval)
        }
        return nil
    }
}

extension UInt8: DBPrimitive {
    public static var ormStoreType: DBStoreType { .INTEGER }
    public static func ormToStoreValue(_ value: UInt8) -> DBStoreValue? {
        _ormToStoreValue(value)
    }
    public static func ormFromStoreValue(_ value: DBStoreValue) -> UInt8? {
        _ormFromStoreValue(value)
    }
}

extension UInt16: DBPrimitive {
    public static var ormStoreType: DBStoreType { .INTEGER }
    public static func ormToStoreValue(_ value: UInt16) -> DBStoreValue? {
        _ormToStoreValue(value)
    }
    public static func ormFromStoreValue(_ value: DBStoreValue) -> UInt16? {
        _ormFromStoreValue(value)
    }
}

extension UInt32: DBPrimitive {
    public static var ormStoreType: DBStoreType { .INTEGER }
    public static func ormToStoreValue(_ value: UInt32) -> DBStoreValue? {
        _ormToStoreValue(value)
    }
    public static func ormFromStoreValue(_ value: DBStoreValue) -> UInt32? {
        _ormFromStoreValue(value)
    }
}

extension UInt64: DBPrimitive {
    public static var ormStoreType: DBStoreType { .INTEGER }
    public static func ormToStoreValue(_ value: UInt64) -> DBStoreValue? {
        return .integer(Int64(bitPattern: value))
    }
    public static func ormFromStoreValue(_ value: DBStoreValue) -> UInt64? {
        if case .integer(let int64) = value {
            return UInt64(bitPattern: int64)
        }
        return nil
    }
}

// MARK: - Double

extension BinaryFloatingPoint {
    @inline(__always)
    static func _ormToStoreValue(_ value: any BinaryFloatingPoint) -> DBStoreValue? {
        if let tval = Double(exactly: value) {
            return .real(tval)
        }
        return nil
    }

    @inline(__always)
    static func _ormFromStoreValue(_ value: DBStoreValue) -> Self? {
        if case .real(let double) = value {
            return Self(exactly: double)
        }
        return nil
    }
}

extension Float: DBPrimitive {
    public static var ormStoreType: DBStoreType { .REAL }
    public static func ormToStoreValue(_ value: Float) -> DBStoreValue? {
        return _ormToStoreValue(value)
    }
    public static func ormFromStoreValue(_ value: DBStoreValue) -> Float? {
        return _ormFromStoreValue(value)
    }
}

extension Double: DBPrimitive {
    public static var ormStoreType: DBStoreType { .REAL }
    public static func ormToStoreValue(_ value: Double) -> DBStoreValue? {
        return _ormToStoreValue(value)
    }
    public static func ormFromStoreValue(_ value: DBStoreValue) -> Double? {
        return _ormFromStoreValue(value)
    }
}

private let _posixLocal = Locale(identifier: "en_US_POSIX")

extension NSNumber: DBPrimitive {
    public static var ormStoreType: DBStoreType { .TEXT }
    
    public static func ormToStoreValue(_ value: NSNumber) -> DBStoreValue? {
        if let decimal = value as? NSDecimalNumber {
            return .text(decimal.description(withLocale: _posixLocal))
        }
        let objcTypeStr = String(cString: value.objCType)
        switch objcTypeStr {
        case "B", "c", "C", "s", "S", "i", "I", "l", "L":
            return Int64.ormToStoreValue(value.int64Value)
        case "q", "Q":
            return UInt64.ormToStoreValue(value.uint64Value)
        case "f", "d":
            return Double.ormToStoreValue(value.doubleValue)
        default:
            return nil
        }
    }
    
    public static func ormFromStoreValue(_ value: DBStoreValue) -> Self? {
        switch value {
        case .text(let text):
            if let decimal = Decimal(string: text, locale: _posixLocal) {
                return NSDecimalNumber(decimal: decimal) as? Self
            }
        case .integer(let int64):
            return Self(value: int64)
        case .real(let double):
            return Self(value: double)
        default:
            break
        }
        return nil
    }
}

// MARK: - String

//extension String: Primitive {}
//extension Data: Primitive {}
//
//extension NSString: Primitive {}
//extension NSData: Primitive {}
//
//extension NSNumber: Primitive {}
////extension NSDecimalNumber: Primitive {} // not support, for databaseValue was override by NSNumber
//extension Decimal: Primitive {}
//extension CGFloat: Primitive {}
//
//extension UUID: Primitive {}
//extension NSUUID: Primitive {}
//
//// GRDB will store date as "yyyy-MM-dd HH:mm:ss.SSS" in database, sometimes will loss precision
//extension Date: Primitive {}
//extension NSDate: Primitive {}
//
//extension NSNull: Primitive {}
