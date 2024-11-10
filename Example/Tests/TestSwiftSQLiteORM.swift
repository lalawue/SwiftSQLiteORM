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
    var nsstring: NSString

    var data: Data
    var nsdata: NSData

    var nsnumber: NSNumber
    var cgfloat: CGFloat
    
    var decimal: Decimal

    var uuid: UUID
    var nsuuid: NSUUID

    var date: Date
    var nsdate: NSDate
    
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
        case nsstring

        case data
        case nsdata

        case nsnumber
        case cgfloat
        
        case decimal

        case uuid
        case nsuuid

        case date
        case nsdate
    }
    
    static func randomValue(_ block: ((inout Self) -> Void)? = nil) -> Self {
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
        let nsstring = string as NSString

        let data = "\(arc4random())".data(using: .utf8) ?? Data(repeating: 54, count: 16)
        let nsdata = data as NSData

        let nsnumber = NSNumber(floatLiteral: double)
        let cgfloat = CGFloat(floatLiteral: double)
        
        let decimal = isTrue() ? Decimal.greatestFiniteMagnitude : Decimal.leastFiniteMagnitude
        
        let uuid = UUID()
        let nsuuid = NSUUID(uuidString: uuid.uuidString)!

        let date = Date()
        let nsdate = NSDate(timeIntervalSince1970: date.timeIntervalSince1970)
        
        var ret = BasicType(bool: bool,
                            bool_opt: nil,
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
                            nsstring: nsstring,
                            data: data,
                            nsdata: nsdata,
                            nsnumber: nsnumber,
                            cgfloat: cgfloat,
                            decimal: decimal,
                            uuid: uuid,
                            nsuuid: nsuuid,
                            date: date,
                            nsdate: nsdate
        )
        block?(&ret)
        return ret
    }
    
    static func ==(lhs: BasicType, rhs: BasicType) -> Bool {
        return ((lhs.bool == rhs.bool) &&
                (lhs.bool_opt == rhs.bool_opt) &&

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
                (lhs.nsstring == rhs.nsstring) &&

                (lhs.data == rhs.data) &&
                (lhs.nsdata == rhs.nsdata) &&

                (lhs.nsnumber == rhs.nsnumber) &&
                (lhs.cgfloat == rhs.cgfloat) &&
                
                (lhs.decimal == rhs.decimal) &&
                
                (lhs.uuid == rhs.uuid) &&
                (lhs.nsuuid == rhs.nsuuid) &&

                // GRDB will store date as "yyyy-MM-dd HH:mm:ss.SSS" in database
                (lhs.date.databaseValue == rhs.date.databaseValue) &&
                (lhs.nsdate.databaseValue == rhs.nsdate.databaseValue)
        )
    }
    
    func print() {
        let str = "bool:\(bool), bool_opt:\(String(describing: bool_opt)), int:\(int), int8:\(int8), int16:\(int16), int32:\(int32), int64:\(int64), uint:\(uint), uint8:\(uint8), uint16:\(uint16), uint32:\(uint32), uint64:\(uint64), float:\(float), double:\(double), string:\(string), nsstring:\(nsstring) data:\(data), nsdata:\(nsdata), nsnumber:\(nsnumber), cgfloat:\(cgfloat), decimal:\(decimal), uuid:\(uuid), nsuuid:\(nsuuid), date:\(date.timeIntervalSinceReferenceDate), nsdate:\(nsdate.timeIntervalSinceReferenceDate)"
        NSLog(str)
    }
}

// MARK: -

struct PlainType2: Codable {
    let pname2: String
    let index2: Int
}

struct PlainType1: Codable {
    let pname1: String
    let pdata1: PlainType2
}

struct NestedType1: Codable {
    let nname: String
    let pdata: PlainType1
}

struct NestedType: DBTableDef, Equatable {
    
    let name: String
    let ndata: NestedType1
    
    typealias ORMKey = columns
    
    enum columns: String, DBTableKey {
        case name
        case ndata
    }
    
    static var primaryKey: ORMKey? {
        return .name
    }
    
    static func randomValue() -> NestedType {
        let index = Int(arc4random())
        let name = "\(index)"
        return NestedType(name: name,
                          ndata: NestedType1(nname: name,
                                             pdata: PlainType1(pname1: name, pdata1: PlainType2(pname2: name, index2: index))))
    }
    
    static func ==(lhs: NestedType, rhs: NestedType) -> Bool {
        return ((lhs.name == rhs.name) &&
                (lhs.ndata.nname == rhs.ndata.nname) &&
                (lhs.ndata.pdata.pname1 == rhs.ndata.pdata.pname1) &&
                (lhs.ndata.pdata.pdata1.pname2 == rhs.ndata.pdata.pdata1.pname2) &&
                (lhs.ndata.pdata.pdata1.index2 == rhs.ndata.pdata.pdata1.index2))
    }
    
    func print() {
        NSLog("NestedType: \(name), \(ndata.nname), \(ndata.pdata.pname1), \(ndata.pdata.pdata1.pname2), \(ndata.pdata.pdata1.index2)")
    }
}

// MARK: -

class Tests: XCTestCase {
    
    override func setUp() {
        super.setUp()
        // Put setup code here. This method is called before the invocation of each test method in the class.
        tryBlock({
            try DBMgnt.clear(BasicType.self)
            try DBMgnt.clear(NestedType.self)
        })
    }
    
    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        super.tearDown()
    }

    func testBasicType() {
        let c = BasicType.randomValue()
        let u = BasicType.randomValue()
        
        //c.print()
        
        do {
            tryBlock({ try DBMgnt.push([c, u] )})
        }

        do {
            let c1 = tryBlock({ try DBMgnt.fetch(BasicType.self, .eq(.int, c.int)) }).first ?? u
            let u1 = tryBlock({ try DBMgnt.fetch(BasicType.self, .eq(.string, u.string)) }).first ?? c

            //c1.print()

            XCTAssert(c1 == c, "Failed")
            XCTAssert(u1 == u, "Failed")
        }

        do {
            tryBlock({ try DBMgnt.delete(BasicType.self, .eq(.int, c.int)) })
            let c1 = tryBlock({ try DBMgnt.fetch(BasicType.self, .eq(.int, c.int)) }).first ?? u
            XCTAssert(c1 == u, "Failed")
        }
        
        do {
            tryBlock({ try DBMgnt.clear(BasicType.self) })
            let all = tryBlock({ try DBMgnt.fetch(BasicType.self) })
            XCTAssert(all.count == 0, "Failed")
        }
    }

    func testNestedType() {
        let c = NestedType.randomValue()
        let u = NestedType.randomValue()
        
        c.print()
        
        do {
            tryBlock({ try DBMgnt.push([c, u]) })
        }
        
        do {
            let c1 = tryBlock({ try DBMgnt.fetch(NestedType.self, .eq(.name, c.name)) }).first ?? u
            let u1 = tryBlock({ try DBMgnt.fetch(NestedType.self, .eq(.name, u.name)) }).first ?? c
            
            c1.print()
            
            XCTAssert(c1 == c, "Failed")
            XCTAssert(u1 == u, "Failed")
        }
        
        do {
            tryBlock({ try DBMgnt.delete(NestedType.self, .eq(.name, c.name)) })
            let c1 = tryBlock({ try DBMgnt.fetch(NestedType.self, .eq(.name, c.name)) }).first ?? u
            XCTAssert(c1 == u, "Failed")
        }
        
        do {
            tryBlock({ try DBMgnt.clear(NestedType.self) })
            let all = tryBlock({ try DBMgnt.fetch(NestedType.self) })
            XCTAssert(all.count == 0, "Failed")
        }
    }
    
    func testRecordFilter() {
        
        tryBlock({
            try DBMgnt.clear(BasicType.self)
            let count = try DBMgnt.fetch(BasicType.self).count
            XCTAssert(count == 0, "Failed")
        })
        
        let c = BasicType.randomValue({
            $0.int = 123
            $0.float = 456
            $0.string = "789"
            $0.data = "987".data(using: .utf8)!
            $0.nsnumber = NSNumber(value: 654)
            $0.decimal = 321
        })
        
        let u = BasicType.randomValue({
            $0.int = 987
            $0.float = 654
            $0.string = "321"
            $0.data = "123".data(using: .utf8)!
            $0.nsnumber = NSNumber(value: 456)
            $0.decimal = 789
        })
        
        tryBlock({ try DBMgnt.push([c, u]) })
        
        // eq
        tryBlock({
            let c1 = try DBMgnt.fetch(BasicType.self, .eq(.int, c.int)).first ?? u
            let u1 = try DBMgnt.fetch(BasicType.self, .eq(.int, u.int)).first ?? c
            XCTAssert(c1 == c, "Failed")
            XCTAssert(u1 == u, "Failed")
        })
        
        // neq
        tryBlock({
            let c1 = try DBMgnt.fetch(BasicType.self, .neq(.string, c.string)).first ?? c
            let u1 = try DBMgnt.fetch(BasicType.self, .neq(.decimal, u.int)).first ?? u
            XCTAssert(c1 == u, "Failed")
            XCTAssert(u1 == c, "Failed")
        })
        
        // gt
        tryBlock({
            let c1 = try DBMgnt.fetch(BasicType.self, .gt(.int, c.int)).first ?? c
            let u1 = try DBMgnt.fetch(BasicType.self, .gt(.nsnumber, u.nsnumber)).first ?? u
            XCTAssert(c1 == u, "Failed")
            XCTAssert(u1 == c, "Failed")
        })
        
        // gte
        tryBlock({
            let c1 = try DBMgnt.fetch(BasicType.self, .gte(.int, c.int)).count
            let u1 = try DBMgnt.fetch(BasicType.self, .gte(.nsnumber, u.nsnumber)).count
            XCTAssert(c1 == 2, "Failed")
            XCTAssert(u1 == 2, "Failed")
        })
        
        // lt
        tryBlock({
            let c1 = try DBMgnt.fetch(BasicType.self, .lt(.int, u.int)).first ?? u
            let u1 = try DBMgnt.fetch(BasicType.self, .lt(.nsnumber, c.nsnumber)).first ?? c
            XCTAssert(c1 == c, "Failed")
            XCTAssert(u1 == u, "Failed")
        })
        
        // lte
        tryBlock({
            let c1 = try DBMgnt.fetch(BasicType.self, .lte(.int, u.int)).count
            let u1 = try DBMgnt.fetch(BasicType.self, .lte(.nsnumber, c.nsnumber)).count
            XCTAssert(c1 == 2, "Failed")
            XCTAssert(u1 == 2, "Failed")
        })
        
        // like
        tryBlock({
            let c1 = try DBMgnt.fetch(BasicType.self, .like(.int, c.int)).first ?? u
            let u1 = try DBMgnt.fetch(BasicType.self, .like(.nsnumber, u.nsnumber)).first ?? c
            XCTAssert(c1 == c, "Failed")
            XCTAssert(u1 == u, "Failed")
        })
        
        // in
        tryBlock({
            let c1 = try DBMgnt.fetch(BasicType.self, .in(.int, [123])).count
            let u1 = try DBMgnt.fetch(BasicType.self, .in(.int, [123, 987])).count
            XCTAssert(c1 == 1, "Failed")
            XCTAssert(u1 == 2, "Failed")
        })
        // between, .not
        tryBlock({
            let c1 = try DBMgnt.fetch(BasicType.self, .between(key: .decimal, 000, 555)).count
            let u1 = try DBMgnt.fetch(BasicType.self, ._key([.int]), .not, .between(000, 999)).count
            XCTAssert(c1 == 1, "Failed")
            XCTAssert(u1 == 0, "Failed")
            NSLog("ucount: \(u1)")
        })
        
        // order by
        tryBlock({
            let c1 = try DBMgnt.fetch(BasicType.self, .orderBy([.int], .ASC)).first ?? u
            let u1 = try DBMgnt.fetch(BasicType.self, .orderBy([.decimal], .DESC)).first ?? c
            XCTAssert(c1 == c, "Failed")
            XCTAssert(u1 == u, "Failed")
        })

        // limit
        tryBlock({
            let c1 = try DBMgnt.fetch(BasicType.self, .limit(1)).count
            XCTAssert(c1 == 1, "Failed")
        })
        
        // raw
        tryBlock({
            let c1 = try DBMgnt.fetch(BasicType.self, ._raw(" WHERE `string` = '321'")).first ?? c
            let u1 = try DBMgnt.fetch(BasicType.self, .gt(.int, 0), ._raw(" AND `decimal` > '555'")).first ?? c
            XCTAssert(c1 == u, "Failed")
            XCTAssert(u1 == u, "Failed")
        })
    }
    
    func testAddColumns() {
        
        // first push 2 FakeType1 to database in orm_FakeType1_t table
        do {
            struct FakeType1: DBTableDef {
                let name: String
                typealias ORMKey = Columns
                enum Columns: String, DBTableKey {
                    case name
                }
            }

            tryBlock({
                try DBMgnt.clear(FakeType1.self)
                try DBMgnt.push([FakeType1(name: "ft11"), FakeType1(name: "ft12")])
                let count = try DBMgnt.fetch(FakeType1.self).count
                XCTAssert(count == 2, "Failed")
                
                // do reset
                try DBMgnt.reset(FakeType1.self)
            })
        }

        // upgrade FakeType1 to FakeType2, add 'index' column
        do {
            struct FakeType1: DBTableDef {
                let name: String
                var index: Int
                typealias ORMKey = Column
                enum Column: String, DBTableKey {
                    case name
                    case index
                }
                static var tableVersion: Double {
                    return 1
                }
                static func ormUpdateNew(_ value: inout FakeType1) -> FakeType1 {
                    if value.name.hasPrefix("ft1") {
                        value.index = 1
                    }
                    return value
                }
            }
            
            tryBlock({
                let arr = try DBMgnt.fetch(FakeType1.self, .orderBy([.name], .ASC))
                XCTAssert(arr.count == 2, "Failed")
                XCTAssert(arr[0].name == "ft11" && arr[0].index == 1, "Failed")
                XCTAssert(arr[1].name == "ft12" && arr[1].index == 1, "Failed")
            })
            
            tryBlock({
                try DBMgnt.push([FakeType1(name: "ft21", index: 2), FakeType1(name: "ft22", index: 2)])
                let arr = try DBMgnt.fetch(FakeType1.self, .like(.name, "ft2%"), .orderBy([.name], .ASC))
                XCTAssert(arr.count == 2, "Failed")
                XCTAssert(arr[0].name == "ft21" && arr[0].index == 2, "Failed")
                XCTAssert(arr[1].name == "ft22" && arr[1].index == 2, "Failed")
                try DBMgnt.reset(FakeType1.self)
            })
        }
    }

    func testMultiThreadRW() {
    }
    
    func testPerformanceExample() {
        // This is an example of a performance test case.
        self.measure() {
            // Put the code you want to measure the time of here.
        }
    }
    
}
