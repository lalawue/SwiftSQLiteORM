//
//  DBPrimitive.swift
//  SwiftSQLiteORM
//
//  Created by lalawue on 2024/11/16.
//

import Runtime
import GRDB

/// database column type
/// - will perform relative type calculation in sql expression
/// - https://sqlite.org/datatype3.html
public enum DBStoreType {

    /// Int64
    case INTEGER
    
    /// Double
    case REAL
    
    /// String, Numeric
    case TEXT

    /// Data
    case BLOB
}

/// database store value type
/// - will sotre as type's DatabaseValueConvertible through GRDB
public enum DBStoreValue {
    
    /// box with int64
    case integer(Int64)

    /// box with double
    case real(Double)

    /// box with String
    case text(String)

    /// box with data
    case blob(Data)
}

/// type transform for store / restore from database
public protocol DBPrimitive: DefaultConstructor {
    
    /// database column type
    static var ormStoreType: DBStoreType { get }
    
    /// return TypeInfo for mocking, for example objc wrapper NSUUID
    static func ormTypeInfo() throws -> TypeInfo

    /// mapping value to store in database
    func ormToStoreValue() -> DBStoreValue?

    /// restore value from database
    static func ormFromStoreValue(_ value: DBStoreValue) -> Self?
}

extension DBPrimitive {
    
    /// buildin some objc wrapper types
    public static func ormTypeInfo() throws -> TypeInfo {
        switch Self.self {
        case _ as NSString.Type: return try ormMockType(as: String.self, NSString.self)
        case _ as NSString?.Type: return try ormMockType(as: String?.self, NSString?.self)
            
        case _ as NSNumber.Type: return try ormMockType(as: Decimal.self, NSNumber.self)
        case _ as NSNumber?.Type: return try ormMockType(as: Decimal?.self, NSNumber?.self)
            
        case _ as NSUUID.Type: return try ormMockType(as: UUID.self, NSUUID.self)
        case _ as NSUUID?.Type: return try ormMockType(as: UUID?.self, NSUUID?.self)
            
        case _ as NSDate.Type: return try ormMockType(as: Date.self, NSDate.self)
        case _ as NSDate?.Type: return try ormMockType(as: Date?.self, NSDate?.self)
            
        case _ as NSData.Type: return try ormMockType(as: Data.self, NSData.self)
        case _ as NSData?.Type: return try ormMockType(as: Data?.self, NSData?.self)
            
        default: return try typeInfo(of: Self.self)
        }
    }
    
    /// replace type or generic type
    public static func ormMockType(as atype: Any.Type, _ ttype: Any.Type) throws -> TypeInfo {
        var ainfo = try typeInfo(of: atype)
        if ainfo.kind == .optional {
            ainfo.genericTypes = [ttype]
        } else {
            ainfo.type = ttype
        }
        return ainfo
    }
    
    internal func grdbValue() -> DatabaseValue? {
        guard let svalue = ormToStoreValue() else {
            return nil
        }
        switch svalue {
        case .integer(let int64): return int64.databaseValue
        case .real(let double): return double.databaseValue
        case .text(let string): return string.databaseValue
        case .blob(let data): return data.databaseValue
        }
    }
}

extension DBStoreValue {
    
    internal func primitiveValue() -> DBPrimitive {
        switch self {
        case .integer(let int64): return int64
        case .real(let double): return double
        case .text(let string): return string
        case .blob(let data): return data
        }
    }
}

extension DatabaseValueConvertible {
    
    internal func dbStoreValue() -> DBStoreValue? {
        switch self {
        case let v as any SignedInteger:
            return .integer(Int64(v))
        case let v as any BinaryFloatingPoint:
            return .real(Double(v))
        case let v as NSNumber:
            switch String(cString: v.objCType) {
            case "c":
                return .integer(Int64(v.int8Value))
            case "C":
                return .integer(Int64(v.uint8Value))
            case "s":
                return .integer(Int64(v.int16Value))
            case "S":
                return .integer(Int64(v.uint16Value))
            case "i":
                return .integer(Int64(v.int32Value))
            case "I":
                return .integer(Int64(v.uint32Value))
            case "l":
                return .integer(Int64(v.intValue))
            case "L":
                return .integer(Int64(bitPattern: v.uint64Value))
            case "q":
                return .integer(Int64(v.int64Value))
            case "Q":
                return .integer(Int64(bitPattern: v.uint64Value))
            case "f":
                return .real(Double(v.floatValue))
            case "d":
                return .real(v.doubleValue)
            case "B":
                return .integer(v.boolValue ? 1 : 0)
            default:
                return nil
            }
        case let v as String:
            return .text(v)
        case let v as Data:
            return .blob(v)

        default:
            return nil
        }
    }
}

// MARK: - Bool, Int64, UInt64

private protocol DBIntegerPrimitive {}

extension DBIntegerPrimitive {

    public static var ormStoreType: DBStoreType { .INTEGER }

    public func ormToStoreValue() -> DBStoreValue? {
        switch self {
        case let val as Bool: return .integer(val ? 1 : 0)
            //
        case let val as Int8: return .integer(Int64(val))
        case let val as Int16: return .integer(Int64(val))
        case let val as Int32: return .integer(Int64(val))
        case let val as Int: return .integer(Int64(val))
        case let val as Int64: return .integer(val)
            //
        case let val as UInt8: return .integer(Int64(val))
        case let val as UInt16: return .integer(Int64(val))
        case let val as UInt32: return .integer(Int64(bitPattern: UInt64(val)))
        case let val as UInt: return .integer(Int64(bitPattern: UInt64(val)))
        //case let val as UInt64: return .integer(Int64(bitPattern: val))
            //
        default: return nil
        }
    }

    public static func ormFromStoreValue<T: DBIntegerPrimitive>(_ value: DBStoreValue) -> T? {
        guard case .integer(let int64) = value else {
            return nil
        }
        switch Self.self {
        case _ as Bool.Type: return (int64 == 1) as? T
            //
        case _ as Int8.Type: return Int8(exactly: int64) as? T
        case _ as Int16.Type: return Int16(exactly: int64) as? T
        case _ as Int32.Type: return Int32(exactly: int64) as? T
        case _ as Int.Type: return Int(exactly: int64) as? T
        case _ as Int64.Type: return int64 as? T
            //
        case _ as UInt8.Type: return UInt8(exactly: int64) as? T
        case _ as UInt16.Type: return UInt16(exactly: int64) as? T
        case _ as UInt32.Type: return UInt32(exactly: UInt64(bitPattern: int64)) as? T
        case _ as UInt.Type: return UInt(exactly: UInt64(bitPattern: int64)) as? T
        //case _ as UInt64.Type: return UInt64(bitPattern: int64) as? T
            //
        default: return nil
        }
    }
}

extension Bool: DBPrimitive, DBIntegerPrimitive {}

extension Int: DBPrimitive, DBIntegerPrimitive {}
extension Int8: DBPrimitive, DBIntegerPrimitive {}
extension Int16: DBPrimitive, DBIntegerPrimitive {}
extension Int32: DBPrimitive, DBIntegerPrimitive {}
extension Int64: DBPrimitive, DBIntegerPrimitive {}

extension UInt: DBPrimitive, DBIntegerPrimitive {}
extension UInt8: DBPrimitive, DBIntegerPrimitive {}
extension UInt16: DBPrimitive, DBIntegerPrimitive {}
extension UInt32: DBPrimitive, DBIntegerPrimitive {}

extension UInt64: DBPrimitive {
    public static var ormStoreType: DBStoreType { .TEXT }
    public func ormToStoreValue() -> DBStoreValue? {
        .text(self.description)
    }
    
    public static func ormFromStoreValue(_ value: DBStoreValue) -> UInt64? {
        if case .text(let string) = value, let v = UInt64(string) {
            return v
        }
        return nil
    }
}

// MARK: - Float, Double, CGFloat

private protocol DBRealPrimitive {}

extension DBRealPrimitive {
    
    public static var ormStoreType: DBStoreType { .REAL }
    
    public func ormToStoreValue() -> DBStoreValue? {
        switch self {
        case let val as Float: return .real(Double(val))
        case let val as Double: return .real(val)
        case let val as CGFloat: return .real(Double(val))
        default: return nil
        }
    }
    
    public static func ormFromStoreValue<T: BinaryFloatingPoint>(_ value: DBStoreValue) -> T? {
        guard case .real(let double) = value else {
            return nil
        }
        switch Self.self {
        case _ as Float.Type: fallthrough
        case _ as Double.Type: fallthrough
        case _ as CGFloat.Type:
            return T(double)
        default: return nil
        }
    }
}

extension Float: DBPrimitive, DBRealPrimitive {}
extension Double: DBPrimitive, DBRealPrimitive {}
extension CGFloat: DBPrimitive, DBRealPrimitive {}

// MARK: - NSNumber, NSDecimalNumber, Decimal

private let _posixLocal = Locale(identifier: "en_US_POSIX")

/// for NSNumber was a boxed value for integer or real, will store as text approximate in Decimal
extension NSNumber: DBPrimitive {
    public static var ormStoreType: DBStoreType { .TEXT }
    
    public func ormToStoreValue() -> DBStoreValue? {
        if let decimal = self as? NSDecimalNumber {
            return .text(decimal.description(withLocale: _posixLocal))
        }
        let objcTypeStr = String(cString: self.objCType)
        switch objcTypeStr {
        case "B", "c", "C", "s", "S", "i", "I", "l", "L":
            return .text(self.int64Value.description)
        case "q", "Q":
            return .text(self.uint64Value.description)
        case "f", "d":
            return .text(self.doubleValue.description)
        default:
            return nil
        }
    }
    
    public static func ormFromStoreValue(_ value: DBStoreValue) -> Self? {
        guard case .text(let text) = value else {
            return nil
        }
        if let _ = Self.self as? NSDecimalNumber.Type,
           let decimal = Decimal(string: text, locale: _posixLocal)
        {
            return NSDecimalNumber(decimal: decimal) as? Self
        }
        if let bool = Bool(text) {
            return NSNumber(booleanLiteral: bool) as? Self
        }
        if let int = Int(text) {
            return NSNumber(integerLiteral: int) as? Self
        }
        if let double = Double(text) {
            return NSNumber(floatLiteral: double) as? Self
        }
        if let decimal = Decimal(string: text, locale: _posixLocal) {
            return NSDecimalNumber(decimal: decimal) as? Self
        }
        return nil
    }
}

extension Decimal: DBPrimitive {
    
    public static var ormStoreType: DBStoreType { .TEXT }

    public func ormToStoreValue() -> DBStoreValue? {
        return .text(self.description)
    }
    
    public static func ormFromStoreValue(_ value: DBStoreValue) -> Decimal? {
        if case .text(let string) = value,
           let decimal = Decimal(string: string, locale: _posixLocal)
        {
            return decimal
        } else {
            return nil
        }
    }
}

// MARK: - String, NSString

private protocol DBTextPrimitive {}

extension DBTextPrimitive {
 
    public static var ormStoreType: DBStoreType { .TEXT }
    
    public func ormToStoreValue() -> DBStoreValue? {
        switch self {
        case let val as String: return .text(val)
        case let val as NSString: return .text(val as String)
        default: return nil
        }
    }
    
    public static func ormFromStoreValue<T: DBTextPrimitive>(_ value: DBStoreValue) -> T? {
        guard case .text(let string) = value else {
            return nil
        }
        switch Self.self {
        case _ as String.Type: return string as? T
        case _ as NSString.Type: return (string as NSString) as? T
        default: return nil
        }
    }
}

extension String: DBPrimitive, DBTextPrimitive {}
extension NSString: DBPrimitive, DBTextPrimitive {}

// MARK: - Data, NSData, UUID, NSUUID

private protocol DBDataPrimitive {}

extension DBDataPrimitive {
    
    public static var ormStoreType: DBStoreType { .BLOB }
    
    public func ormToStoreValue() -> DBStoreValue? {
        switch self {
        case let val as Data: return .blob(val)
        case let val as NSData: return .blob(val as Data)
        case let val as UUID:
            return .blob(withUnsafeBytes(of: val.uuid) {
                Data(bytes: $0.baseAddress!, count: $0.count)
            })
        case let val as NSUUID:
            var uuidBytes = ContiguousArray(repeating: UInt8(0), count: 16)
            return .blob(uuidBytes.withUnsafeMutableBufferPointer { buffer in
                val.getBytes(buffer.baseAddress!)
                return NSData(bytes: buffer.baseAddress, length: 16) as Data
            })
        default:
            return nil
        }
    }
    
    public static func ormFromStoreValue<T: DBDataPrimitive>(_ value: DBStoreValue) -> T? {
        guard case .blob(let data) = value else {
            return nil
        }
        switch Self.self {
        case _ as Data.Type: return data as? T
        case _ as NSData.Type: return (data as Data) as? T
        case _ as UUID.Type:
            if data.count == 16 {
                return data.withUnsafeBytes { UUID(uuid: $0.bindMemory(to: uuid_t.self).first!) } as? T
            }
        case _ as NSUUID.Type:
            if  data.count == 16 {
                return data.withUnsafeBytes { NSUUID(uuidBytes: $0.bindMemory(to: UInt8.self).baseAddress) } as? T
            }
        default:
            break
        }
        return nil
    }
}

extension Data: DBPrimitive, DBDataPrimitive {}
extension NSData: DBPrimitive, DBDataPrimitive {}

extension UUID: DBPrimitive, DBDataPrimitive {}
extension NSUUID: DBPrimitive, DBDataPrimitive {}

// MARK: - Date, NSDate

private let dbDateFormatter: DateFormatter = {
    let formatter = DateFormatter()
    formatter.dateFormat = "yyyy-MM-dd HH:mm:ss.SSS"
    formatter.locale = Locale(identifier: "en_US_POSIX")
    formatter.timeZone = TimeZone(secondsFromGMT: 0)
    return formatter
}()

private protocol DBDatePrimitive {}

extension DBDatePrimitive {
    
    public static var ormStoreType: DBStoreType { .TEXT }
    
    public func ormToStoreValue() -> DBStoreValue? {
        switch self {
        case let val as Date: return .text(dbDateFormatter.string(from: val))
        case let val as NSDate: return .text(dbDateFormatter.string(from: val as Date))
        default: return nil
        }
    }
    
    public static func ormFromStoreValue<T: DBDatePrimitive>(_ value: DBStoreValue) -> T? {
        guard case .text(let string) = value else {
            return nil
        }
        switch Self.self {
        case _ as Date.Type: return dbDateFormatter.date(from: string) as? T
        case _ as NSDate.Type: return dbDateFormatter.date(from: string) as? T
        default: return nil
        }
    }
}

extension Date: DBPrimitive, DBDatePrimitive {}
extension NSDate: DBPrimitive, DBDatePrimitive {}
