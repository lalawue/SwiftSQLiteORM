//
//  DBTableDefHelper.swift
//  SwiftSQLiteORM
//
//  Created by lalawue on 2024/11/7.
//

import Runtime

/// TableDef helper, store table property type info
class DBTableDefHelper {
    
    private let infoCache = DBCache<TypeInfo>()
    
    private static let shared = DBTableDefHelper()
    
    private init() {
    }
    
    /// get table definition properties
    static func getInfo(_ def: DBTableDef.Type) -> TypeInfo? {
        let tname = def.tableName
        if let info = shared.infoCache[tname] {
            return info
        }
        if let info = try? typeInfo(of: def) {
            shared.infoCache[tname] = info
            return info
        }
        return nil
    }
}
