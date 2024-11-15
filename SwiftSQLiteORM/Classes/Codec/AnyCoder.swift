//
//  AnyCoder.swift
//  AnyCoder
//
//  Created by Valo on 2020/7/30.
//

import Foundation
import Runtime

class AnyEncoder {
    /*
    class func encode<T: DBTableDef>(pcmap: [String:String], _ any: T) throws -> [String: Primitive] {
        guard let temp = reflect(any) as? [String: Any] else {
            throw EncodingError.invalidEncode(any)
        }
        let cset = Set<String>(pcmap.values)
        var encoded: [String: Primitive] = [:]
        for (key, value) in temp {
            guard cset.contains(key) else {
                continue
            }
            switch value {
            case let value as Primitive:
                if let v = value as? UInt64 {
                    encoded[key] = Int64(bitPattern: v)
                } else {
                    encoded[key] = value
                }
            case _ as NSNull:
                break
            default:
                let data = try JSONSerialization.data(withJSONObject: value, options: [])
                let string = String(bytes: data.bytes)
                encoded[key] = string
            }
        }
        return encoded
    }

    class func encode<T: DBTableDef>(pcmap: [String:String], _ values: [T]) -> [[String: Primitive]] {
        var array = [[String: Primitive]]()
        for value in values {
            do {
                let encoded = try encode(pcmap: pcmap, value)
                array.append(encoded)
            } catch _ {
                array.append([:])
            }
        }
        return array
    }

    class func reflect<T: DBTableDef>(_ any: T) -> Any? {
        return reflect(element: any)
    }
    */
    
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

    // MARK: - Private
    
    /*

    private class func reflect<T: DBTableDef>(element: T) -> Any? {
        guard let result = value(for: element, depth: 0) else {
            return nil
        }
        switch result {
        case _ as [Any], _ as [String: Any]:
            return result
        default:
            return [result]
        }
    }

    private class func value(for any: Any, depth: Int) -> Any? {
        if let primitive = any as? Primitive {
            if depth > 1, let data = primitive as? Data {
                return data.hex
            }
            return primitive
        }
        if let date = any as? Date {
            return date.timeIntervalSinceReferenceDate
        }
        if let date = any as? NSDate {
            return date.timeIntervalSinceReferenceDate
        }

        let mirror = Mirror(reflecting: any)
        if mirror.children.isEmpty {
            switch any {
            case _ as Primitive:
                return any
            case _ as Optional<Any>:
                if let displayStyle = mirror.displayStyle {
                    switch displayStyle {
                    case .enum:
                        return value(forEnum: any)
                    default:
                        return nil
                    }
                }
            default:
                return String(describing: any)
            }
        } else if let displayStyle = mirror.displayStyle {
            switch displayStyle {
            case .class, .dictionary, .struct:
                return dictionary(from: mirror, depth: depth)
            case .collection, .set, .tuple:
                return array(from: mirror, depth: depth)
            case .enum, .optional:
                return value(for: mirror.children.first!.value, depth: depth)
            @unknown default:
                print("not matched")
                return nil
            }
        }
        return nil
    }

    private class func dictionary(from mirror: Mirror, depth: Int) -> [String: Any] {
        return mirror.children.reduce(into: [String: Any]()) {
            var key: String!
            var value: Any!
            if let label = $1.label {
                key = label
                value = $1.value
            } else {
                let array = self.array(from: Mirror(reflecting: $1.value), depth: depth + 1)
                guard 2 <= array.count,
                      let newKey = (array[0] as? String) else {
                    return
                }
                key = newKey
                value = array[1]
            }
            if let value = self.value(for: value!, depth: depth + 1) {
                $0[key] = value
            }
        }
    }

    private class func array(from mirror: Mirror, depth: Int) -> [Any] {
        return mirror.children.compactMap {
            value(for: $0.value, depth: depth)
        }
    }

    private class func value(forEnum item: Any) -> Primitive {
        if let item = item as? (any RawRepresentable),
           let raw = item.rawValue as? Primitive {
            return raw
        }
        let p1 = withUnsafePointer(to: item) { $0 }
        let p2 = p1.withMemoryRebound(to: UInt8.self, capacity: 1) { $0 }
        return p2.pointee
    }
    */
}

class AnyDecoder {
    
    static let emptySet = Set<String>()
    
    class func decode<T: DBTableDef>(_ type: T.Type, from containers: [[String: Primitive]]) throws -> [T] {
        return try containers.map { try decode(type, from: $0) }
    }

    class func decode<T: DBTableDef>(_ type: T.Type, from container: [String: Primitive]) throws -> T {
        guard let result = try createObject(type, from: container) as? T else {
            throw DecodingError.mismatch(type)
        }
        return result
    }

    class func createObject(_ type: Any.Type, from container: [String: Any]) throws -> Any {
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
            guard let value = container[prop.name] else { continue }
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
                case is String.Type: fallthrough
                case is NSString?.Type: fallthrough
                case is NSString.Type:
                    try prop.set(value: string, on: &object)

                case is Data?.Type: fallthrough
                case is Data.Type: fallthrough
                case is NSData?.Type: fallthrough
                case is NSData.Type:
                    let data = Data(hex: string)
                    try prop.set(value: data, on: &object)
                    
                case is UUID.Type: fallthrough
                case is UUID?.Type: fallthrough
                case is NSUUID.Type: fallthrough
                case is NSUUID?.Type:
                    try prop.set(value: string, on: &object)

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
            } else if let dictionary = value as? [String : Any] {
                let sub = try createObject(prop.type, from: dictionary)
                try prop.set(value: sub, on: &object)
            }
        }

        if var obj = object as? any DBTableDef {
            return objUpdateNew(&obj)
        } else {
            return object
        }
    }
}
