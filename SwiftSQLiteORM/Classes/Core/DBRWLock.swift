//
//  DBLock.swift
//  SwiftSQLiteORM
//
//  Created by lalawue on 2024/11/6.
//

import Foundation

final class DBRWLock<T> {

    var value: T {
        get {
            pthread_rwlock_rdlock(&_lock)
            let v = _value
            pthread_rwlock_unlock(&_lock)
            return v
        }
        set {
            pthread_rwlock_wrlock(&_lock)
            _value = newValue
            pthread_rwlock_unlock(&_lock)
        }
    }
    
    private var _value: T
    private var _lock = pthread_rwlock_t()
    
    deinit {
        pthread_rwlock_destroy(&_lock)
    }
    
    init(_ value: T) {
        _value = value
        pthread_rwlock_init(&_lock, nil)
    }
    
    func read<V>(_ block: (T) -> V ) -> V {
        pthread_rwlock_rdlock(&_lock)
        let v = block(_value)
        pthread_rwlock_unlock(&_lock)
        return v
    }
    
    func write(_ block: (inout T) -> Void) {
        pthread_rwlock_wrlock(&_lock)
        block(&_value)
        pthread_rwlock_unlock(&_lock)
    }
}
