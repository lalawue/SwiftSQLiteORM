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
    do {
        let info: TypeInfo
        if let ptype = tinfo as? any DBPrimitive.Type {
            info = try ptype.ormTypeInfo()
        } else {
            info = try typeInfo(of: tinfo)
        }
        _infoCache[tname] = info
        return info
    } catch {
        throw DBORMError.FailedToGetTypeInfo(typeName: "\(tinfo.self)")
    }
}

func rtTypeClear(of tinfo: Any.Type) {
    _infoCache["\(tinfo)"] = nil
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
    guard let rtype = try? rtTypeInfo(of: rawType) else {
        return .blob
    }
    var rt = rawType
    if rtype.kind == .optional {
        if rtype.genericTypes.count == 1 {
            rt = rtype.genericTypes.first!
        }
    }
    if let rt = rt as? any DBPrimitive.Type {
        switch rt.ormStoreType {
        case .INTEGER: return .integer
        case .TEXT: return .text
        case .REAL: return .double
        case .BLOB: return .blob
        }
    }
    return .blob
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

extension AnyDecoder {
    
    /// decode from GRDB's ROW
    class func decode<T: DBTableDef>(_ type: T.Type,
                                     _ pcmap: [String:String],
                                     from row: Row) throws -> T
    {
        guard let result = try createObjectV1(type, pcmap, from: row) as? T else {
            throw DecodingError.mismatch(type)
        }
        return result
    }
    
//    /// row version, for row's key is column name
//    class func createObject(_ type: Any.Type, _ pcmap: [String:String], from row: Row) throws -> Any {
//        var info = try rtTypeInfo(of: type)
//        let genericType: Any.Type
//        if info.kind == .optional {
//            guard info.genericTypes.count == 1 else {
//                throw DecodingError.mismatch(type)
//            }
//            genericType = info.genericTypes.first!
//            info = try rtTypeInfo(of: genericType)
//        } else {
//            genericType = type
//        }
//        var object = try xCreateInstance(of: genericType)
//        for prop in info.properties {
//            guard let cname = pcmap[prop.name], let value = row[cname] else {
//                continue
//            }
//            let xinfo = try rtTypeInfo(of: prop.type)
//            var did = false
//            if let xval = value as? Primitive {
//                if let _ = prop.type as? UInt64.Type,
//                   let xval = xval as? Int64
//                {
//                    let val = UInt64(bitPattern: xval)
//                    try prop.set(value: val, on: &object)
//                    did = true
//                } else if let pt = prop.type as? Primitive.Type,
//                          let val = pt.init(primitive: xval)
//                {
//                    try prop.set(value: val, on: &object)
//                    did = true
//                }
//            }
//            if !did {
//                if xinfo.kind == .optional,
//                   xinfo.genericTypes.count == 1,
//                   let xval = value as? Primitive {
//                    let gpt = xinfo.genericTypes.first!
//                    if let pt = gpt as? Primitive.Type,
//                       let val = pt.init(primitive: xval) {
//                        try prop.set(value: val, on: &object)
//                        did = true
//                    }
//                } else if xinfo.kind == .enum {
//                    if let t = prop.type as? any RawRepresentable.Type, let v = value as? Primitive {
//                        if let val = t.init(primitive: v) {
//                            try prop.set(value: val, on: &object)
//                            did = true
//                        }
//                    } else if let xval = value as? UInt8 {
//                        let pval = UnsafeMutableRawPointer.allocate(byteCount: xinfo.size, alignment: xinfo.alignment)
//                        pval.storeBytes(of: xval, as: UInt8.self)
//                        defer { pval.deallocate() }
//                        try setProperties(typeInfo: xinfo, pointer: pval)
//                        let val = getters(type: prop.type).get(from: pval)
//                        try prop.set(value: val, on: &object)
//                        did = true
//                    }
//                }
//            }
//            if !did {
//                var double: Double?
//                if let float = value as? any BinaryFloatingPoint {
//                    double = Double(float)
//                } else if let num = value as? NSNumber {
//                    double = num.doubleValue
//                }
//                if let double = double {
//                    switch prop.type {
//                    case is Date?.Type: fallthrough
//                    case is Date.Type:
//                        let date = Date(timeIntervalSinceReferenceDate: double)
//                        try prop.set(value: date, on: &object)
//                        did = true
//
//                    case is NSDate?.Type: fallthrough
//                    case is NSDate.Type:
//                        let date = NSDate(timeIntervalSinceReferenceDate: double)
//                        try prop.set(value: date, on: &object)
//                        did = true
//
//                    default:
//                        break
//                    }
//                }
//            }
//            if !did, let string = value as? String {
//                switch prop.type {
//                case is String?.Type: fallthrough
//                case is String.Type:
//                    try prop.set(value: string, on: &object)
//
//                case is Data?.Type: fallthrough
//                case is Data.Type:
//                    let data = Data(hex: string)
//                    try prop.set(value: data, on: &object)
//
//                default:
//                    let data = Data(string.bytes)
//                    let json = try? JSONSerialization.jsonObject(with: data, options: [])
//                    switch json {
//                    case let array as [[String: Any]]:
//                        var subs: [Any] = []
//                        for dictionary in array {
//                            if let sub = try? createObject(prop.type, from: dictionary) {
//                                subs.append(sub)
//                            }
//                        }
//                        try prop.set(value: subs, on: &object)
//
//                    case let array as [Any]:
//                        switch xinfo.kind {
//                        case .optional:
//                            if xinfo.genericTypes.count == 1 {
//                                let gpt = xinfo.genericTypes.first!
//                                let yinfo = try rtTypeInfo(of: gpt)
//                                if yinfo.kind == .tuple, let tuple = array.splat(array.count) {
//                                    try prop.set(value: tuple, on: &object)
//                                } else {
//                                    try prop.set(value: array, on: &object)
//                                }
//                            }
//                            break
//                        case .tuple:
//                            if let tuple = array.splat(array.count) {
//                                try prop.set(value: tuple, on: &object)
//                            }
//                        default:
//                            try prop.set(value: array, on: &object)
//                        }
//
//                    case let dictionary as [String: Any]:
//                        let sub = try createObject(prop.type, from: dictionary)
//                        try prop.set(value: sub, on: &object)
//
//                    default:
//                        break
//                    }
//                }
//            }
//        }
//
//        if var obj = object as? any DBTableDef {
//            return objUpdateNew(&obj)
//        } else {
//            return object
//        }
//    }
    
    @inlinable
    class func objUpdateNew<T: DBTableDef>(_ value: inout T) -> T {
        return T.ormUpdateNew(&value)
    }
    
    /// row version, for row's key is column name
    class func createObjectV1(_ type: Any.Type, _ pcmap: [String:String], from row: Row) throws -> Any {
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
        var object = try xCreateInstance(of: genericType)
        for prop in info.properties {
            guard let cname = pcmap[prop.name],
                  let value = try? row[cname]?.dbStoreValue(tname: "\(type.self)", pname: prop.name) else {
                continue
            }
            let xinfo = try rtTypeInfo(of: prop.type)
            //
            if let xtype = prop.type as? any DBPrimitive.Type,
               let xval = xtype.ormFromStoreValue(value)
            {
                try prop.set(value: xval, on: &object)
                continue
            }
            //
            if xinfo.kind == .optional,
               xinfo.genericTypes.count == 1,
               let xtype = xinfo.genericTypes.first! as? any DBPrimitive.Type,
               let xval = xtype.ormFromStoreValue(value)
            {
                try prop.set(value: xval, on: &object)
                continue
            }
            //
            if xinfo.kind == .enum {
                if let t = prop.type as? any RawRepresentable.Type,
                   let xtype = prop.type as? any DBPrimitive.Type,
                   let xval = xtype.ormFromStoreValue(value)
                {
                    if let val = t.init(primitive: xval) {
                        try prop.set(value: val, on: &object)
                        continue
                    }
                } else if case .integer(let int64) = value,
                          let xval = UInt8(exactly: int64)
                {
                    let pval = UnsafeMutableRawPointer.allocate(byteCount: xinfo.size, alignment: xinfo.alignment)
                    pval.storeBytes(of: xval, as: UInt8.self)
                    defer { pval.deallocate() }
                    try setProperties(typeInfo: xinfo, pointer: pval)
                    let val = getters(type: prop.type).get(from: pval)
                    try prop.set(value: val, on: &object)
                    continue
                }
            }
            //
            if let _ = prop.type as? Codable,
               case .text(let string) = value
            {
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
        
        if var obj = object as? any DBTableDef {
            return objUpdateNew(&obj)
        } else {
            return object
        }
    }
}

extension AnyEncoder {
    
    /// using Runtime but SDK's mirror to encode value to [column_name : value]
    class func encode<T: DBTableDef>(_ values: [T]) throws -> [[String: any DBPrimitive]] {
        var info = try T._typeInfo()
        let genericType: Any.Type
        if info.kind == .optional {
            guard info.genericTypes.count == 1 else {
                throw EncodingError.invalidType(type: info.type)
            }
            genericType = info.genericTypes.first!
            info = try rtTypeInfo(of: genericType)
        } else {
            genericType = info.type
        }
        info = try rtTypeInfo(of: genericType)
        //
        let tname = "\(T.self)"
        let pcmap = T._nameMapping()
        return try values.reduce(into: [[String: any DBPrimitive]](), { (array, value) in
            let encoded = try encodeV1(tname: tname, pcmap: pcmap, value: value, info: info)
            array.append(encoded)
        })
    }
    
//    private class func encode<T: DBTableDef>(tname: String,
//                                             pcmap: [String:String],
//                                             value: T,
//                                             info: TypeInfo) throws -> [String: Primitive]
//    {
//        return try info.properties.reduce(into: [String:Primitive](), { (pvs, prop) in
//            let pname = prop.name
//            guard let cname = pcmap[pname] else { return }
//            let v = try prop.get(from: value)
//            if let v1 = try AnyEncoder.encode(tname: tname, pname: pname, prop: prop, v) {
//                pvs[cname] = v1
//            }
//        })
//    }
//    
//    /// with first level value only support Primitive or Encodable
//    private class func encode(tname: String, pname: String, prop: PropertyInfo, _ val: Any) throws -> Primitive? {
//        switch val {
//        case let pval as Primitive:
//            if let pval = pval as? UInt64 {
//                return Int64(bitPattern: pval)
//            } else {
//                return pval
//            }
//        case let oval as Optional<Any>:
//            switch oval {
//            case .none:
//                return nil
//            case .some(let sval):
//                switch sval {
//                case let spval as Primitive:
//                    if let spval = spval as? UInt64 {
//                        return Int64(bitPattern: spval)
//                    } else {
//                        return spval
//                    }
//                default:
//                    if let ocval = sval as? Codable {
//                        let data = try JSONEncoder().encode(ocval)
//                        return String(bytes: data.bytes)
//                    }
//                    let sinfo = try propertyTypeInfo(tname: tname, pname: pname, type(of: sval))
//                    switch sinfo.kind {
//                    case .enum:
//                        return value(forEnum: sval)
//                    case .tuple:
//                        let arr = try sinfo.properties.reduce(into: [Primitive](), {
//                            if let v = try encode(tname: tname, pname: pname, prop: $1, try $1.get(from: sval)) {
//                                $0.append(v)
//                            }
//                        })
//                        let data = try JSONSerialization.data(withJSONObject: arr)
//                        return String(bytes: data.bytes)
//                   default:
//                        throw DBORMError.FailedToEncodeProperty(typeName: tname, propertyName: pname)
//                    }
//                }
//            }
//        default:
//            if let cval = val as? Codable {
//                let data = try JSONEncoder().encode(cval)
//                return String(bytes: data.bytes)
//            }
//            let info = try propertyTypeInfo(tname: tname, pname: pname, type(of: val))
//            switch info.kind {
//            case .enum:
//                return value(forEnum: val)
//            case .tuple:
//                let arr = try info.properties.reduce(into: [Primitive](), {
//                    if let v = try encode(tname: tname, pname: pname, prop: $1, try $1.get(from: val)) {
//                        $0.append(v)
//                    }
//                })
//                let data = try JSONSerialization.data(withJSONObject: arr)
//                return String(bytes: data.bytes)
//            default:
//                throw DBORMError.FailedToEncodeProperty(typeName: tname, propertyName: pname)
//            }
//        }
//    }
    
    @inline(__always)
    private class func propertyTypeInfo(tname: String, pname: String, _ tinfo: Any.Type) throws -> TypeInfo {
        do {
            return try rtTypeInfo(of: tinfo)
        } catch {
            throw DBORMError.FailedToEncodeProperty(typeName: tname, propertyName: pname)
        }
    }
    
    private class func encodeV1<T: DBTableDef>(tname: String,
                                               pcmap: [String:String],
                                               value: T,
                                               info: TypeInfo) throws -> [String: any DBPrimitive]
    {
        return try info.properties.reduce(into: [String: any DBPrimitive](), { (pvs, prop) in
            let pname = prop.name
            guard let cname = pcmap[pname] else { return }
            let v = try prop.get(from: value)
            if let v1 = try AnyEncoder.encodeV1(tname: tname, pname: pname, prop: prop, v) {
                pvs[cname] = v1
            }
        })
    }
    
    /// with first level value only support Primitive or Encodable
    private class func encodeV1(tname: String, pname: String, prop: PropertyInfo, _ val: Any) throws -> (any DBPrimitive)? {
        switch val {
        case let pval as any DBPrimitive:
            return pval
        case let oval as Optional<Any>:
            switch oval {
            case .none:
                return nil
            case .some(let sval):
                switch sval {
                case let spval as any DBPrimitive:
                    return spval
                default:
                    if let ocval = sval as? Codable {
                        let data = try JSONEncoder().encode(ocval)
                        return String(bytes: data.bytes)
                    }
                    let sinfo = try propertyTypeInfo(tname: tname, pname: pname, type(of: sval))
                    switch sinfo.kind {
                    case .enum:
                        return valueV1(forEnum: sval)
                    case .tuple:
                        let arr = try sinfo.properties.reduce(into: [any DBPrimitive](), {
                            if let v = try encodeV1(tname: tname, pname: pname, prop: $1, try $1.get(from: sval)) {
                                $0.append(v)
                            }
                        })
                        let data = try JSONSerialization.data(withJSONObject: arr)
                        return String(bytes: data.bytes)
                    default:
                        throw DBORMError.FailedToEncodeProperty(typeName: tname, propertyName: pname)
                    }
                }
            }
        default:
            if let ocval = val as? Codable {
                let data = try JSONEncoder().encode(ocval)
                return String(bytes: data.bytes)
            }
            let sinfo = try propertyTypeInfo(tname: tname, pname: pname, type(of: val))
            switch sinfo.kind {
            case .enum:
                return valueV1(forEnum: val)
            case .tuple:
                let arr = try sinfo.properties.reduce(into: [any DBPrimitive](), {
                    if let v = try encodeV1(tname: tname, pname: pname, prop: $1, try $1.get(from: val)) {
                        $0.append(v)
                    }
                })
                let data = try JSONSerialization.data(withJSONObject: arr)
                return String(bytes: data.bytes)
            default:
                throw DBORMError.FailedToEncodeProperty(typeName: tname, propertyName: pname)
            }
        }
    }
    
    class func valueV1(forEnum item: Any) -> any DBPrimitive {
        if let item = item as? (any RawRepresentable),
           let raw = item.rawValue as? any DBPrimitive {
            return raw
        }
        let p1 = withUnsafePointer(to: item) { $0 }
        let p2 = p1.withMemoryRebound(to: UInt8.self, capacity: 1) { $0 }
        return p2.pointee
    }
}

extension RawRepresentable {
    
    init?(primitive: any DBPrimitive) {
        guard let val = primitive as? Self.RawValue else { return nil }
        self.init(rawValue: val)
    }
}
