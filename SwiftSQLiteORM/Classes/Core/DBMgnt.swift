//
//  DBWrapper.swift
//  SwiftSQLiteORM
//
//  Created by lalawue on 2024/11/6.
//

import Foundation
import GRDB
import Runtime

final class DBMgnt {
    
    private var tblInfos = DBRWLock<[String:TypeInfo]>([:])
    
    // MARK: -
    
    private static let shared = DBMgnt()
    
    private init() {
//        guard let pinfo = Self.propertiesInfo(DBSchemaTable.self) else {
//            dbLog(isError: true, "faild to get schema table type info")
//            return
//        }
//        let tname = DBSchemaTable.tableName
//        var sversion: Double = -1
//        try? DBEngine.read(DBSchemaTable.self, {
//            if let ret = try Row.fetchAll($0,
//                                          sql: "SELECT version from \(tname) WHERE tname = ?",
//                                          arguments: [tname]).first
//            {
//                sversion = ret["version"] ?? -1
//            }
//        })
    }

    /// get table definition properties
    static func propertiesInfo(_ tbl: DBTableDef.Type) -> TypeInfo? {
        let tname = tbl.tableName
        if let info = shared.tblInfos.read({ $0[tname] }) {
            return info
        }
        var info: TypeInfo?
        shared.tblInfos.write({
            info = try? typeInfo(of: tbl.self)
            $0[tname] = info
        })
        return info
    }
    
    public static func createTable(_ tbl: DBTableDef.Type) {
        do {
            try DBEngine.write(tbl, {
                try $0.create(table: tbl.tableName, ifNotExists: true, body: {
                    $0.column("name", .text).primaryKey(onConflict: .fail)
                })
            })
            try DBEngine.write(tbl, {
                try $0.execute(sql: "INSERT INTO \(tbl.tableName) (name) VALUES (?)", arguments: ["xixi"])
                dbLog("insert into table")
            })
            try DBEngine.read(tbl, {
                let ret = try Row.fetchAll($0, sql: "SELECT * from \(tbl.tableName)")
                dbLog("fetch all \(ret[0]["name"] ?? "")")
            })
        } catch {
            dbLog(isError: true, error.localizedDescription)
        }
    }
}
