//
//  DBLog.swift
//  SwiftSQLiteORM
//
//  Created by lalawue on 2024/11/6.
//

import Foundation

@inline(__always)
func dbLog(isError: Bool = false, _ text: String) {
    if isError {
        print("[SQLiteORM.Err] \(text)")
    } else {
#if DEBUG
        print("[SQLiteORM.Info] \(text)")
#endif
    }
}
