//
//  DBTableRecord.swift
//  SwiftSQLiteORM
//
//  Created by lalawue on 2024/11/6.
//

import GRDB

/// GRDB Record mapping, CURD manipulate
final class DBTableRecord<T: DBTableDef>: Record {
    
    private let row = Row()
    private var hasMapping = false
    
    required init(row: Row) {
        super.init(row: self.row)
    }
    
    static func fetchAll(db: Database,
                         sql: String,
                         arguments: StatementArguments? = nil) -> [T] {
        guard let records = try? super.fetchAll(db, sql: sql, arguments: arguments ?? StatementArguments()) as? [Self] else {
            return []
        }
        let rows = records.map({ $0.row })
        return []
    }

    @discardableResult
    static func pushAll(values: [T]) -> Bool {
        return false
    }
    
    override class var databaseTableName: String {
        return T.tableName
    }
}
