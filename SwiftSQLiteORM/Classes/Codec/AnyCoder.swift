//
//  AnyCoder.swift
//  AnyCoder
//
//  Created by Valo on 2020/7/30.
//

import Foundation
import Runtime
import GRDB

// here is the modified version of AnyCoder by lalawue

class AnyDecoder {
    
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
    
    /// row version, for row's key is column name
    private class func createObject(_ type: Any.Type, _ pcmap: [String:String], from row: Row) throws -> Any {
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
                  let value = row[cname]?.dbStoreValue() else {
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
                if let t = prop.type as? any RawRepresentable.Type {
                    if let val = t.init(primitive: value.primitiveValue()) {
                        try prop.set(value: val, on: &object)
                        continue
                    }
                } else if case .integer(let int64) = value,
                          let xval = UInt16(exactly: int64)
                {
                    let pval = UnsafeMutableRawPointer.allocate(byteCount: xinfo.size, alignment: xinfo.alignment)
                    pval.storeBytes(of: xval, as: UInt16.self)
                    defer { pval.deallocate() }
                    try setProperties(typeInfo: xinfo, pointer: pval)
                    let val = getters(type: prop.type).get(from: pval)
                    try prop.set(value: val, on: &object)
                    continue
                }
            }
            //
            if case .text(let string) = value {
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
    
    private class func createObject(_ type: Any.Type, from container: [String: Any]) throws -> Any {
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
            guard prop.name.count > 0, let value = container[prop.name] else {
                continue
            }
            let xinfo = try rtTypeInfo(of: prop.type)
            //
            if let xtype = prop.type as? any DBPrimitive.Type,
               let dvalue = (value as? DatabaseValueConvertible)?.dbStoreValue(),
               let xval = xtype.ormFromStoreValue(dvalue)
            {
                try prop.set(value: xval, on: &object)
                continue
            }
            //
            if xinfo.kind == .optional,
               xinfo.genericTypes.count == 1,
               let xtype = xinfo.genericTypes.first! as? any DBPrimitive.Type,
               let dvalue = (value as? DatabaseValueConvertible)?.dbStoreValue(),
               let xval = xtype.ormFromStoreValue(dvalue)
            {
                try prop.set(value: xval, on: &object)
                continue
            }
            //
            if xinfo.kind == .enum {
                if let t = prop.type as? any RawRepresentable.Type,
                   let dvalue = value as? DBPrimitive
                {
                    if let val = t.init(primitive: dvalue) {
                        try prop.set(value: val, on: &object)
                        continue
                    }
                } else if let int64 = value as? any BinaryInteger,
                          let xval = UInt16(exactly: int64)
                {
                    let pval = UnsafeMutableRawPointer.allocate(byteCount: xinfo.size, alignment: xinfo.alignment)
                    pval.storeBytes(of: xval, as: UInt16.self)
                    defer { pval.deallocate() }
                    try setProperties(typeInfo: xinfo, pointer: pval)
                    let val = getters(type: prop.type).get(from: pval)
                    try prop.set(value: val, on: &object)
                    continue
                }
            }
            //
            if let string = value as? String {
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
                    continue

                case let array as [Any]:
                    switch xinfo.kind {
                    case .optional:
                        if xinfo.genericTypes.count == 1 {
                            let gpt = xinfo.genericTypes.first!
                            let yinfo = try rtTypeInfo(of: gpt)
                            if yinfo.kind == .tuple, let tuple = array.splat(array.count) {
                                try prop.set(value: tuple, on: &object)
                                continue
                            } else {
                                try prop.set(value: array, on: &object)
                                continue
                            }
                        }
                        break
                    case .tuple:
                        if let tuple = array.splat(array.count) {
                            try prop.set(value: tuple, on: &object)
                            continue
                        }
                    default:
                        try prop.set(value: array, on: &object)
                        continue
                    }

                case let dictionary as [String: Any]:
                    let sub = try createObject(prop.type, from: dictionary)
                    try prop.set(value: sub, on: &object)
                    continue

                default:
                    break
                }
            }
            //
            if let dictionary = value as? [String : Any] {
                let sub = try createObject(prop.type, from: dictionary)
                try prop.set(value: sub, on: &object)
                continue
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

class AnyEncoder {
    
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
            let encoded = try encode(tname: tname, pcmap: pcmap, value: value, info: info)
            array.append(encoded)
        })
    }
    
    private class func encode<T: DBTableDef>(tname: String,
                                               pcmap: [String:String],
                                               value: T,
                                               info: TypeInfo) throws -> [String: any DBPrimitive]
    {
        return try info.properties.reduce(into: [String: any DBPrimitive](), { (pvs, prop) in
            let pname = prop.name
            guard let cname = pcmap[pname] else { return }
            let v = try prop.get(from: value)
            if let v1 = try AnyEncoder.encode(tname: tname, pname: pname, prop: prop, v) {
                pvs[cname] = v1
            }
        })
    }
    
    /// with first level value only support Primitive or Encodable
    private class func encode(tname: String, pname: String, prop: PropertyInfo, _ val: Any) throws -> (any DBPrimitive)? {
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
                        return value(forEnum: sval)
                    case .tuple:
                        let arr = try sinfo.properties.reduce(into: [any DBPrimitive](), {
                            if let v = try encode(tname: tname, pname: pname, prop: $1, try $1.get(from: sval)) {
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
                return value(forEnum: val)
            case .tuple:
                let arr = try sinfo.properties.reduce(into: [any DBPrimitive](), {
                    if let v = try encode(tname: tname, pname: pname, prop: $1, try $1.get(from: val)) {
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
    
    private class func value(forEnum item: Any) -> any DBPrimitive {
        if let item = item as? (any RawRepresentable),
           let raw = item.rawValue as? any DBPrimitive {
            return raw
        }
        let p1 = withUnsafePointer(to: item) { $0 }
        let p2 = p1.withMemoryRebound(to: UInt8.self, capacity: 1) { $0 }
        return p2.pointee
    }
    
    private class func propertyTypeInfo(tname: String, pname: String, _ tinfo: Any.Type) throws -> TypeInfo {
        do {
            return try rtTypeInfo(of: tinfo)
        } catch {
            throw DBORMError.FailedToEncodeProperty(typeName: tname, propertyName: pname)
        }
    }
    
    /// get primary key value in depth 0
    class func reflectPrimaryValue<T: DBTableDef>(_ any: T) -> Any? {
        guard let cname = T.primaryKey?.rawValue else {
            return nil
        }
        let mirror = Mirror(reflecting: any)
        let p2c = T._nameMapping()
        for (label, value) in mirror.children {
            if let pname = label, let cname1 = p2c[pname], cname1 == cname {
                return value
            }
        }
        return nil
    }
}

extension RawRepresentable {
    
    init?(primitive: any DBPrimitive) {
        guard let val = primitive as? Self.RawValue else { return nil }
        self.init(rawValue: val)
    }
}
