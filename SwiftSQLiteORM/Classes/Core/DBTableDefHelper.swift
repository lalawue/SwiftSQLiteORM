//
//  DBTableDefHelper.swift
//  SwiftSQLiteORM
//
//  Created by lalawue on 2024/11/7.
//

import Foundation
import Runtime

/// TableDef helper, store table property type info
final class DBTableDefHelper {
    
    private let infoCache = NSCache<NSString,DBClsValue<TypeInfo>>()
    
    private static let shared = DBTableDefHelper()
    
    private init() {
    }
    
    /// get table definition properties
    static func getInfo(_ tbl: DBTableDef.Type) -> TypeInfo? {
        let tname = tbl.tableName
        if let info = shared.infoCache.object(forKey: tname as NSString)?.value {
            return info
        }
        if let info = try? typeInfo(of: tbl.self) {
            shared.infoCache.setObject(DBClsValue(info), forKey: tname as NSString)
            return info
        }
        return nil
    }
}
