//
//  DBCache.swift
//  SwiftSQLiteORM
//
//  Created by lalawue on 2024/11/7.
//

import Foundation

/// NSCache wrapper
class DBCache<T> {
    
    private let cache = NSCache<NSString,DBClsValue<T>>()
    
    @inlinable
    subscript(_ key: String) -> T? {
        get {
            return cache.object(forKey: key as NSString)?.value
        }
        set {
            if let value = newValue {
                cache.setObject(DBClsValue(value), forKey: key as NSString)
            } else {
                cache.removeObject(forKey: key as NSString)
            }
        }
    }
}

/// wrapper value into class object
private class DBClsValue<T> {
    
    let value: T
    
    init(_ value: T) {
        self.value = value
    }
}
