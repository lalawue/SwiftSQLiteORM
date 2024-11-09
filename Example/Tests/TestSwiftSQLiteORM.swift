//
//  TestSwiftSQLiteORM.swift
//  SwiftSQLiteORM_Example
//
//  Created by lalawue on 2024/11/9.
//  Copyright © 2024 CocoaPods. All rights reserved.
//

import XCTest
import SwiftSQLiteORM

@inlinable
func isTrue() -> Bool {
    return arc4random() % 2 == 1
}

@inlinable
func orNil<T>(_ value: T) -> T? {
    return isTrue() ? value : nil
}

@inlinable
func tryBlock<T>(_ block: () throws -> T) -> T {
    do {
        return try block()
    } catch {
        fatalError("failed to try block: \(error.localizedDescription)")
    }
}

struct BasicType: DBTableDef, Equatable {
    
    var bool: Bool
    var bool_opt: Bool?
    
    var int: Int
    var int8: Int8
    var int16: Int16
    var int32: Int32
    var int64: Int64

    var uint: UInt
    var uint8: UInt8
    var uint16: UInt16
    var uint32: UInt32
    var uint64: UInt64

    var float: Float
    var double: Double

    var string: String
    //var nsstring: NSString
    
    var data: Data
    //var nsdata: NSData
    
    //var nsnumber: NSNumber
    var cgfloat: CGFloat
    
    typealias ORMKey = Columns
    
    enum Columns: String, DBTableKey {
        case bool
        case bool_opt
        
        case int
        case int8
        case int16
        case int32
        case int64

        case uint
        case uint8
        case uint16
        case uint32
        case uint64

        case float
        case double

        case string
        //case nsstring
        
        case data
        //case nsdata
        
        //case nsnumber
        case cgfloat
    }
    
    mutating func changeCopy(_ block: (inout Self) -> Void) -> Self {
        var v = self
        block(&v)
        return v
    }
    
    static func randomValue() -> Self {
        let bool = isTrue()
        let int = Int(truncatingIfNeeded: arc4random())
        let int8 = Int8(truncatingIfNeeded: arc4random())
        let int16 = Int16(truncatingIfNeeded: arc4random())
        let int32 = Int32(truncatingIfNeeded: arc4random())
        let int64 = isTrue() ? Int64.max : Int64.min
        
        let uint = UInt(truncatingIfNeeded: arc4random())
        let uint8 = UInt8(truncatingIfNeeded: arc4random())
        let uint16 = UInt16(truncatingIfNeeded: arc4random())
        let uint32 = UInt32(truncatingIfNeeded: arc4random())
        let uint64 = UInt64.max
        
        let float = isTrue() ? Float.greatestFiniteMagnitude : (-Float(arc4random()) / 7)
        let double = isTrue() ? Double.greatestFiniteMagnitude : (-Double(arc4random()) / 7)
        
        let string = "\(arc4random())"
        //let nsstring = string as NSString
        
        let data = "\(arc4random())".data(using: .utf8) ?? Data(repeating: 54, count: 16)
        //let nsdata = data as NSData
        
        //let nsnumber = NSNumber(floatLiteral: double)
        let cgfloat = CGFloat(floatLiteral: double)
        
        return BasicType(bool: bool,
                         bool_opt: orNil(bool),
                         int: int,
                         int8: int8,
                         int16: int16,
                         int32: int32,
                         int64: int64,
                         uint: uint,
                         uint8: uint8,
                         uint16: uint16,
                         uint32: uint32,
                         uint64: uint64,
                         float: float,
                         double: double,
                         string: string,
//                         nsstring: nsstring,
                         data: data,
                         //nsdata: nsdata,
//                         nsnumber: nsnumber,
                         cgfloat: cgfloat)
    }
    
    static func ==(lhs: BasicType, rhs: BasicType) -> Bool {
        return ((lhs.bool == rhs.bool) &&
//                (lhs.bool_opt == rhs.bool_opt) &&
                
                (lhs.int == rhs.int) &&
                (lhs.int8 == rhs.int8) &&
                (lhs.int16 == rhs.int16) &&
                (lhs.int32 == rhs.int32) &&
                (lhs.int64 == rhs.int64) &&

                (lhs.uint == rhs.uint) &&
                (lhs.uint8 == rhs.uint8) &&
                (lhs.uint16 == rhs.uint16) &&
                (lhs.uint32 == rhs.uint32) &&
                (lhs.uint64 == rhs.uint64) &&

                (lhs.float == rhs.float) &&
                (lhs.double == rhs.double) &&
                
                (lhs.string == rhs.string) &&
//                (lhs.nsstring == rhs.nsstring) &&
                
                (lhs.data == rhs.data) &&
//                (lhs.nsdata == rhs.nsdata) &&
                
//                (lhs.nsnumber == rhs.nsnumber) &&
                (lhs.cgfloat == rhs.cgfloat))
    }
    
    func print() {
        let str = "bool:\(bool), bool_opt:\(String(describing: bool_opt)), int:\(int), int8:\(int8), int16:\(int16), int32:\(int32), int64:\(int64), uint:\(uint), uint8:\(uint8), uint16:\(uint16), uint32:\(uint32), uint64:\(uint64), float:\(float), double:\(double), string:\(string), data:\(data), cgfloat:\(cgfloat)"
        NSLog(str)
    }
}

class Tests: XCTestCase {
    
    override func setUp() {
        super.setUp()
        // Put setup code here. This method is called before the invocation of each test method in the class.
        tryBlock({ try DBMgnt.clear(BasicType.self) })
    }
    
    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        super.tearDown()
    }
    
    func testBasicTypeCURD() {
        let c = BasicType.randomValue()
        let u = BasicType.randomValue()
        
        do {
            tryBlock({ try DBMgnt.push([c, u] )})
        }
        
        do {
            let c1 = tryBlock({ try DBMgnt.fetch(BasicType.self, .eq(.int, c.int)) }).first ?? u
            let u1 = tryBlock({ try DBMgnt.fetch(BasicType.self, .eq(.string, u.string)) }).first ?? c
            
            XCTAssert(c1 == c, "Failed")
            XCTAssert(u1 == u, "Failed")
        }
        
        do {
            tryBlock({ try DBMgnt.delete(BasicType.self, .eq(.int, c.int)) })
            let c1 = tryBlock({ try DBMgnt.fetch(BasicType.self, .eq(.int, c.int)) }).first ?? u
            XCTAssert(c1 == u, "Failed")
        }
    }
    
    func testPerformanceExample() {
        // This is an example of a performance test case.
        self.measure() {
            // Put the code you want to measure the time of here.
        }
    }
    
}
