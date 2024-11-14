//
//  DBLog.swift
//  SwiftSQLiteORM
//
//  Created by lalawue on 2024/11/6.
//

import GRDB
import Runtime

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

// MARK: - Type Info

private let _infoCache = DBCache<TypeInfo>()

/// cache type info if needed
func rtTypeInfo(of tinfo: Any.Type) throws -> TypeInfo {
    let tname = "\(tinfo)"
    if let info = _infoCache[tname] {
        return info
    }
    let info: TypeInfo
    switch tinfo {
    case is NSString.Type:
        info = try fakeType(String.self, NSString.self)
    case is NSString?.Type:
        info = try fakeType(String?.self, NSString.self)
    case is NSData.Type:
        info = try fakeType(Data.self, NSData.self)
    case is NSData?.Type:
        info = try fakeType(Data?.self, NSData.self)
    case is NSNumber.Type:
        info = try fakeType(Decimal.self, NSNumber.self)
    case is NSNumber?.Type:
        info = try fakeType(Decimal?.self, NSNumber.self)
    case is NSDate.Type:
        info = try fakeType(Date.self, NSDate.self)
    case is NSDate?.Type:
        info = try fakeType(Date?.self, NSDate.self)
    case is NSUUID.Type:
        info = try fakeType(UUID.self, NSUUID.self)
    case is NSUUID?.Type:
        info = try fakeType(UUID?.self, NSUUID.self)
    default:
        info = try typeInfo(of: tinfo)
    }
    _infoCache[tname] = info
    return info
}

func rtTypeClear(of tinfo: Any.Type) {
    _infoCache["\(tinfo)"] = nil
}

/// replace type or generic type
private func fakeType(_ rtype: Any.Type, _ ttype: Any.Type) throws -> TypeInfo {
    var tinfo = try typeInfo(of: rtype)
    if tinfo.kind == .optional {
        tinfo.genericTypes = [ttype]
    } else {
        tinfo.type = ttype
    }
    return tinfo
}

// MARK: - Name Mapping

private let _p2cCache = DBCache<[String:String]>()

func ormNameMapping<T: DBTableDef>(_ def: T.Type) -> [String: String] {
    let tname = "\(def)"
    if let p2c = _p2cCache[tname]  {
        return p2c
    } else {
        var p2c: [String:String] = [:]
        def.ORMKey.allCases.forEach {
            p2c["\($0)"] = $0.rawValue
        }
        _p2cCache[tname] = p2c
        return p2c
    }
}

func ormNameMappingClear<T: DBTableDef>(_ def: T.Type) {
    _p2cCache["\(def)"] = nil
}

// MARK: Column Type

func getColumnType(rawType: Any.Type) -> Database.ColumnType {
    switch rawType {
    case is Bool.Type: fallthrough
    case is Bool?.Type:
        return .boolean
    case is any BinaryInteger.Type: fallthrough
    case is (any BinaryInteger)?.Type:
        return .integer
    case is any BinaryFloatingPoint.Type: fallthrough
    case is (any BinaryFloatingPoint)?.Type:
        return .double
    case is String.Type: fallthrough
    case is String?.Type: fallthrough
    case is NSString.Type: fallthrough
    case is NSString?.Type:
        return .text
    case is Date.Type: fallthrough
    case is Date?.Type: fallthrough
    case is NSDate.Type: fallthrough
    case is NSDate?.Type:
        return .datetime
    case is NSNumber.Type: fallthrough
    case is NSNumber?.Type:
        return .numeric
        

    case is Decimal.Type: fallthrough
    case is Decimal?.Type:
        // store as 'String' in databaseValue
        return .blob
        

    case is Date.Type: fallthrough
    case is Date?.Type: fallthrough
    case is NSDate.Type: fallthrough
    case is Date?.Type:
        // store as 'String' in databaseValue
        return .blob


    case is UUID.Type: fallthrough
    case is UUID?.Type: fallthrough
    case is NSUUID.Type: fallthrough
    case is NSUUID?.Type:
        // store as 'Data' in databaseValue
        return .blob

    case is Data.Type: fallthrough
    case is Data?.Type: fallthrough
    case is NSData.Type: fallthrough
    case is NSData?.Type: fallthrough
    default:
        return .blob
    }
}

extension Dictionary where Key == String {
    
    func _remapKeys(_ map: [Key:Key]) -> [Key:Value] {
        let nkvs = self.compactMap { (key, value) in
            if let nkey = map[key] {
                return (nkey, value)
            } else {
                return nil
            }
        }
        return Dictionary(uniqueKeysWithValues: nkvs)
    }
}

extension Primitive {

    /// see GRDB StandardLibrary
    var databaseValue: DatabaseValue {
        return 0.databaseValue
    }

    /// see GRDB StandardLibrary
    static func fromDatabaseValue(_ dbValue: DatabaseValue) -> Primitive? {
        return nil
    }
}

extension AnyDecoder {
    
    /// decode from GRDB's ROW
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
            guard let value = row[cname] else { continue }
            let xinfo = try rtTypeInfo(of: prop.type)
            var did = false
            if let xval = value as? Primitive {
                if let _ = prop.type as? UInt64.Type,
                   let xval = xval as? Int64
                {
                    let val = UInt64(bitPattern: xval)
                    try prop.set(value: val, on: &object)
                    did = true
                } else if let pt = prop.type as? Primitive.Type,
                          let val = pt.init(primitive: xval)
                {
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

        if var obj = object as? any DBTableDef {
            return objUpdateNew(&obj)
        } else {
            return object
        }
    }
    
    @inlinable
    class func objUpdateNew<T: DBTableDef>(_ value: inout T) -> T {
        return T.ormUpdateNew(&value)
    }
}
