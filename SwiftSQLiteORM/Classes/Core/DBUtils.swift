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
