//
//  DBLog.swift
//  SwiftSQLiteORM
//
//  Created by lalawue on 2024/11/6.
//

import GRDB
import Runtime

private let _infoCache = DBCache<TypeInfo>()

/// cache type info if needed
func rtTypeInfo(of tinfo: Any.Type) throws -> TypeInfo {
    let tname = "\(tinfo)"
    if let info = _infoCache[tname] {
        return info
    } else {
        let info = try typeInfo(of: tinfo)
        _infoCache[tname] = info
        return info
    }
}

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
    
    var databaseValue: DatabaseValue {
        switch self {
        case let v as Bool:
            return v.databaseValue
        case let v as Int:
            return v.databaseValue
        case let v as Int8:
            return v.databaseValue
        case let v as Int16:
            return v.databaseValue
        case let v as Int32:
            return v.databaseValue
        case let v as Int64:
            return v.databaseValue
        case let v as UInt:
            return v.databaseValue
        case let v as UInt8:
            return v.databaseValue
        case let v as UInt16:
            return v.databaseValue
        case let v as UInt32:
            return v.databaseValue
        case let v as UInt64:
            return v.databaseValue
        case let v as Float:
            return v.databaseValue
        case let v as Double:
            return v.databaseValue
        case let v as String:
            return v.databaseValue
        case let v as Data:
            return v.databaseValue
        case let v as NSNumber:
            return v.databaseValue
        case let v as NSString:
            return v.databaseValue
        case let v as NSData:
            return v.databaseValue
        case let v as  CGFloat:
            return v.databaseValue
        default:
            return NSNull().databaseValue
        }
    }
    
    static func fromDatabaseValue(_ dbValue: DatabaseValue) -> Primitive? {
        switch dbValue.storage {
        case .blob(let value):
            return value
        case .int64(let value):
            return value
        case .double(let value):
            return value
        case .string(let value):
            return value
        case .null:
            return nil
        }
    }
}

extension AnyDecoder {
    
    class func decode<T: DBTableDef>(_ type: T.Type,
                                     _ pcmap: [String:String],
                                     from row: Row) throws -> T
    {
        guard let result = try createObject(type, pcmap, from: row) as? T else {
            throw DecodingError.mismatch(type)
        }
        return result
    }
    
    class func createObject(_ type: Any.Type, _ pcmap: [String:String], from row: Row) throws -> Any {
        var info = try rtTypeInfo(of: type)
        let genericType: Any.Type
        if info.kind == .optional {
            guard info.genericTypes.count == 1 else {
                throw DecodingError.mismatch(type)
            }
            genericType = info.genericTypes.first!
            info = try rtTypeInfo(of: genericType)
        } else {
            genericType = type
        }
        let tset: Set<String>
        if let def = type as? any DBTableDef.Type {
            tset = def._reservedNameSet()
        } else {
            tset = Self.emptySet
        }
        var object = try xCreateInstance(of: genericType)
        for prop in info.properties {
            if prop.name.isEmpty || tset.contains(prop.name) { continue }
            guard let cname = pcmap[prop.name] else { continue }
            if let value = row[cname] {
                let xinfo = try rtTypeInfo(of: prop.type)
                var did = false
                if let xval = value as? Primitive {
                    if let pt = prop.type as? Primitive.Type,
                       let val = pt.init(primitive: xval) {
                        try prop.set(value: val, on: &object)
                        did = true
                    }
                }
                if !did {
                    if xinfo.kind == .optional,
                       xinfo.genericTypes.count == 1,
                       let xval = value as? Primitive {
                        let gpt = xinfo.genericTypes.first!
                        if let pt = gpt as? Primitive.Type,
                           let val = pt.init(primitive: xval) {
                            try prop.set(value: val, on: &object)
                            did = true
                        }
                    } else if xinfo.kind == .enum {
                        if let t = prop.type as? any RawRepresentable.Type, let v = value as? Primitive {
                            if let val = t.init(primitive: v) {
                                try prop.set(value: val, on: &object)
                                did = true
                            }
                        } else if let xval = value as? UInt8 {
                            let pval = UnsafeMutableRawPointer.allocate(byteCount: xinfo.size, alignment: xinfo.alignment)
                            pval.storeBytes(of: xval, as: UInt8.self)
                            defer { pval.deallocate() }
                            try setProperties(typeInfo: xinfo, pointer: pval)
                            let val = getters(type: prop.type).get(from: pval)
                            try prop.set(value: val, on: &object)
                            did = true
                        }
                    }
                }
                if !did {
                    var double: Double?
                    if let float = value as? any BinaryFloatingPoint {
                        double = Double(float)
                    } else if let num = value as? NSNumber {
                        double = num.doubleValue
                    }
                    if let double = double {
                        switch prop.type {
                        case is Date?.Type: fallthrough
                        case is Date.Type:
                            let date = Date(timeIntervalSinceReferenceDate: double)
                            try prop.set(value: date, on: &object)
                            did = true

                        case is NSDate?.Type: fallthrough
                        case is NSDate.Type:
                            let date = NSDate(timeIntervalSinceReferenceDate: double)
                            try prop.set(value: date, on: &object)
                            did = true

                        default:
                            break
                        }
                    }
                }
                if !did, let string = value as? String {
                    switch prop.type {
                    case is String?.Type: fallthrough
                    case is String.Type:
                        try prop.set(value: string, on: &object)

                    case is Data?.Type: fallthrough
                    case is Data.Type:
                        let data = Data(hex: string)
                        try prop.set(value: data, on: &object)

                    default:
                        let data = Data(string.bytes)
                        let json = try? JSONSerialization.jsonObject(with: data, options: [])
                        switch json {
                        case let array as [[String: Any]]:
                            var subs: [Any] = []
                            for dictionary in array {
                                if let sub = try? createObject(prop.type, from: dictionary) {
                                    subs.append(sub)
                                }
                            }
                            try prop.set(value: subs, on: &object)

                        case let array as [Any]:
                            switch xinfo.kind {
                            case .optional:
                                if xinfo.genericTypes.count == 1 {
                                    let gpt = xinfo.genericTypes.first!
                                    let yinfo = try rtTypeInfo(of: gpt)
                                    if yinfo.kind == .tuple, let tuple = array.splat(array.count) {
                                        try prop.set(value: tuple, on: &object)
                                    } else {
                                        try prop.set(value: array, on: &object)
                                    }
                                }
                                break
                            case .tuple:
                                if let tuple = array.splat(array.count) {
                                    try prop.set(value: tuple, on: &object)
                                }
                            default:
                                try prop.set(value: array, on: &object)
                            }

                        case let dictionary as [String: Any]:
                            let sub = try createObject(prop.type, from: dictionary)
                            try prop.set(value: sub, on: &object)

                        default:
                            break
                        }
                    }
                }
            }
        }

        return object
    }
}
