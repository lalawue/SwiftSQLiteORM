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
        if let err = error as? DBORMError {
            fatalError("failed to try block: \(err.localizedDescription)")
        } else {
            fatalError("failed to try block: \(error.localizedDescription)")
        }
    }
}

enum BasicEnum: String {
    case a = "aaa"
    case b = "bbb"
}

enum SeqEnum {
    case c
    case d
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
    var nsdecimal: NSDecimalNumber

    var uuid: UUID
    var nsuuid: NSUUID

    var date: Date
    var nsdate: NSDate
    
    var benum: BasicEnum
    var senum: SeqEnum
    var btuple: (a:Int, b:String)
    
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
        case nsdecimal

        case uuid
        case nsuuid

        case date
        case nsdate
        
        case benum
        case senum
        case btuple
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
        let uint32 = UInt32.max
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
        let nsdecimal = NSDecimalNumber(decimal: decimal)
        
        let uuid = UUID()
        let nsuuid = NSUUID(uuidString: uuid.uuidString)!

        let date = Date()
        let nsdate = NSDate(timeIntervalSince1970: date.timeIntervalSince1970)
        
        let benum: BasicEnum = isTrue() ? .a : .b
        let senum: SeqEnum = isTrue() ? .c : .d
        let btuple: (a: Int, b: String) = (Int(arc4random()), "\(arc4random())")
        
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
                            nsdecimal: nsdecimal,
                            uuid: uuid,
                            nsuuid: nsuuid,
                            date: date,
                            nsdate: nsdate,
                            benum: benum,
                            senum: senum,
                            btuple: btuple
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
                (lhs.nsdecimal == rhs.nsdecimal) &&
                
                (lhs.uuid == rhs.uuid) &&
                (lhs.nsuuid == rhs.nsuuid) &&

                // GRDB will store date as "yyyy-MM-dd HH:mm:ss.SSS" in database
                (lhs.date.databaseValue == rhs.date.databaseValue) &&
                (lhs.nsdate.databaseValue == rhs.nsdate.databaseValue) &&
                
                (lhs.benum == rhs.benum) &&
                (lhs.senum == rhs.senum) &&
                ((lhs.btuple.a == rhs.btuple.a) && (lhs.btuple.b == rhs.btuple.b))
        )
    }
    
    func print(_ prefix: String = "") {
        let str = "bool:\(bool), bool_opt:\(String(describing: bool_opt)), int:\(int), int8:\(int8), int16:\(int16), int32:\(int32), int64:\(int64), uint:\(uint), uint8:\(uint8), uint16:\(uint16), uint32:\(uint32), uint64:\(uint64), float:\(float), double:\(double), string:\(string), nsstring:\(nsstring) data:\(data), nsdata:\(nsdata), nsnumber:\(nsnumber), cgfloat:\(cgfloat), decimal:\(decimal), nsdecimal:\(nsdecimal), uuid:\(uuid), nsuuid:\(nsuuid), date:\(date.timeIntervalSinceReferenceDate), nsdate:\(nsdate.timeIntervalSinceReferenceDate) benum:\(benum.rawValue), senum:\(senum.hashValue), btuple:(a:\(btuple.a),b:\(btuple.b)"
        NSLog("\(prefix.isEmpty ? "" : ("\(prefix)" + " "))---\n" + str + "\n---")
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

extension URL: DBPrimitive {
    
    public init() {
        // will be placed by database value later
        self.init(string: "a://a.a")!
    }
    
    public static var ormStoreType: SwiftSQLiteORM.DBStoreType { .TEXT }
    
    public func ormToStoreValue() -> SwiftSQLiteORM.DBStoreValue? {
        return .text(self.absoluteString)
    }
    
    public static func ormFromStoreValue(_ value: SwiftSQLiteORM.DBStoreValue) -> URL? {
        guard case .text(let string) = value else {
            return nil
        }
        return URL(string: string)
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
        
        c.print("c")
        u.print("u")
        
        do {
            tryBlock({
                try DBMgnt.push([c, u])
                let count = try DBMgnt.fetch(BasicType.self).count
                XCTAssert(count == 2, "Failed")
            })
        }

        do {
            let c1 = tryBlock({ try DBMgnt.fetch(BasicType.self, .eq(.int, c.int)) }).first ?? u
            let u1 = tryBlock({ try DBMgnt.fetch(BasicType.self, .eq(.string, u.string)) }).first ?? c

            c1.print("c1")

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
    
    func testReadmeExample() {

        // nested struct will store as JSON string
        struct ExampleNested: Codable {
            let desc: String
            let index: Int
        }

        struct ExampleType: DBTableDef {
            let name: String
            let data: ExampleNested

            typealias ORMKey = Columns
            
            /// keep blank or return nil for using hidden 'rowid' column
            static var primaryKey: Columns? {
                return .name
            }
            
            enum Columns: String, DBTableKey {
                case name
                case data
            }
        }
        
        do {
            // insert / update
            let c = ExampleType(name: "c", data: ExampleNested(desc: "c", index: 1))
            let u = ExampleType(name: "u", data: ExampleNested(desc: "u", index: 2))
            try DBMgnt.push([c, u])
            
            // select
            let arr = try DBMgnt.fetch(ExampleType.self, .eq(.name, c.name))
            XCTAssert(arr.count == 1, "failed")
            XCTAssert(arr[0].name == c.name, "failed")
            
            // delete
            try DBMgnt.deletes([c]) // require primaryKey in table definition
            try DBMgnt.delete(ExampleType.self, .eq(.name, u.name))
            let count = try DBMgnt.fetch(ExampleType.self, .eq(.name, c.name)).count
            XCTAssert(count == 0, "failed")
            
            // clear
            try DBMgnt.clear(ExampleType.self)
            
            // drop table
            try DBMgnt.drop(ExampleType.self)

        } catch {
            if let err = error as? DBORMError {
                fatalError("failed to try block: \(err.localizedDescription)")
            } else {
                fatalError("failed to try block: \(error.localizedDescription)")
            }
        }
    }
    
    func testInvalidType() {
        struct InvalidType: DBTableDef {
            let name: String
            let value: NSLock
            typealias ORMKey = Columns
            enum Columns: String, DBTableKey {
                case name = "cname"
                case value = "cvalue"
            }
        }
        let c = InvalidType(name: "c", value: NSLock())
        let u = InvalidType(name: "u", value: NSLock())
        do {
            try DBMgnt.push([c, u])
        } catch {
            print("success catch error: \((error as? DBORMError)?.localizedDescription ?? "-")")
            switch error {
            case DBORMError.FailedToEncodeProperty(let typeName, let propertyName):
                XCTAssert(typeName == "\(InvalidType.self)")
                XCTAssert(propertyName == "value")
            default:
                XCTAssert(false, "Failed")
            }
        }
    }
    
    func testDBPrimitiveProtocol() {
        // make sure 'URL' conforms to DBPrimitive (not provided by SwiftSQLiteORM by default)
        struct ExtendURLType: DBTableDef {
            let url: URL
            typealias ORMKey = Columns
            enum Columns: String, DBTableKey {
                case url
            }
        }
        let c = ExtendURLType(url: URL(string: "http://123.com")!)
        let u = ExtendURLType(url: URL(string: "http://456.com")!)
        tryBlock({
            try DBMgnt.push([c, u])
            let c1 = try DBMgnt.fetch(ExtendURLType.self, .like(.url, "%123%")).first ?? u
            XCTAssert(c1.url == c.url, "Failed")
        })
    }
    
    func testDeleteValue() {
        struct CheckDelete: DBTableDef {
            let value: Int
            static var primaryKey: ORMKey? {
                return .value
            }
            typealias ORMKey = Columns
            enum Columns: String, DBTableKey {
                case value
            }
            static func randomValue() -> CheckDelete {
                return CheckDelete(value: Int(arc4random()))
            }
        }
        
        let tcount = 128
        let values = stride(from: 0, to: tcount, by: 1).map({ _ in CheckDelete.randomValue() })
        
        tryBlock({
            try DBMgnt.push(values)
            try DBMgnt.deletes(values)
            let rets = try DBMgnt.fetch(CheckDelete.self)
            XCTAssert(rets.count == 0, "Failed")
        })
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
            $0.uint32 = UInt32.max
            $0.uint64 = 1
            $0.nsnumber = NSNumber(value: 654)
            $0.decimal = 321
        })
        
        let u = BasicType.randomValue({
            $0.int = 987
            $0.float = 654
            $0.string = "321"
            $0.data = "123".data(using: .utf8)!
            $0.uint32 = 1
            $0.uint64 = UInt64.max
            $0.nsnumber = NSNumber(value: 456)
            $0.decimal = 789
        })
        
        tryBlock({ try DBMgnt.push([c, u]) })
        
        // eq
        tryBlock({
            let c1 = try DBMgnt.fetch(BasicType.self, .eq(.uint32, c.uint32)).first ?? u
            let u1 = try DBMgnt.fetch(BasicType.self, .eq(.uint64, UInt64.max)).first ?? c
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
            let c1 = try DBMgnt.fetch(BasicType.self, .gt(.uint64, UInt64.max - 1)).first ?? c
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
            let c1 = try DBMgnt.fetch(BasicType.self, .orderBy(.int, .ASC)).first ?? u
            let u1 = try DBMgnt.fetch(BasicType.self, .orderByKeys([(.decimal, .DESC)])).first ?? c
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

        struct FakeType1: DBTableDef {
            let name: String
            typealias ORMKey = Columns
            enum Columns: String, DBTableKey {
                case name
            }
        }

        tryBlock({
            // first drop all table data
            try DBMgnt.drop(FakeType1.self)
        })

        tryBlock({
            try DBMgnt.push([FakeType1(name: "ft11"), FakeType1(name: "ft12")])
            let count = try DBMgnt.fetch(FakeType1.self).count
            XCTAssert(count == 2, "Failed")
        })

        // here use FakeType2 to emulate upgraded FakeType1 in next app cold start

        struct FakeType2: DBTableDef {
            let name: String
            var index: Int
            typealias ORMKey = Column
            enum Column: String, DBTableKey {
                case name
                case index
            }
            static var tableName: String {
                return FakeType1.tableName
            }
            static var tableVersion: Double {
                return 1
            }
            static func ormUpdateNew(_ value: inout FakeType2) -> FakeType2 {
                if value.name.hasPrefix("ft1") {
                    value.index = 1 // reset FakeType1 index to 1
                }
                return value
            }
        }
        
        tryBlock({
            let arr = try DBMgnt.fetch(FakeType2.self, .orderBy(.name, .ASC))
            XCTAssert(arr.count == 2, "Failed")
            XCTAssert(arr[0].name == "ft11" && arr[0].index == 1, "Failed")
            XCTAssert(arr[1].name == "ft12" && arr[1].index == 1, "Failed")
        })
        
        tryBlock({
            try DBMgnt.push([FakeType2(name: "ft21", index: 2), FakeType2(name: "ft22", index: 2)])
            let arr = try DBMgnt.fetch(FakeType2.self, .like(.name, "ft2%"), .orderBy(.name, .ASC))
            XCTAssert(arr.count == 2, "Failed")
            XCTAssert(arr[0].name == "ft21" && arr[0].index == 2, "Failed")
            XCTAssert(arr[1].name == "ft22" && arr[1].index == 2, "Failed")
        })
    }

    func testMultiThreadRW() {
        let tcount = 6
        var varray = Array<BasicType>()
        
        while varray.count < tcount {
            varray.append(BasicType.randomValue({
                $0.decimal = Decimal(tcount - varray.count)
            }))
        }
        
        print("fill with varray: \(varray.count)")
        
        // clear all data first
        tryBlock({
            try DBMgnt.clear(BasicType.self)
        })
        
        var tarray = Array<Thread>()
        while tarray.count < tcount {
            let tindex = tarray.count
            tarray.append(Thread(block: {
                var run_times = 0
                while run_times < 2000 {
                    run_times += 1
                    if run_times % 100 == 0 {
                        print("ThreadRW[\(tindex)] run times: \(run_times)")
                    }
                    let vindex = Int(arc4random()) % tcount
                    switch arc4random() % 3 {
                    case 0:
                        let _ = tryBlock({ try DBMgnt.fetch(BasicType.self, .eq(.decimal, varray[vindex].decimal)) })
                    case 1:
                        tryBlock({ try DBMgnt.push([varray[vindex]]) })
                    default:
                        tryBlock({ try DBMgnt.delete(BasicType.self, .eq(.decimal, varray[vindex].decimal)) })
                    }
                }
            }))
        }
        
        // start all threads
        tarray.forEach {
            $0.start()
        }
        
        // waiting all finished
        while true {
            var finished_count = 0
            tarray.forEach {
                finished_count += ($0.isFinished ? 1 : 0)
            }
            if finished_count == tcount {
                break
            }
            usleep(1)
        }
        
        // check result
        tryBlock({
            var vindex = 0
            while vindex < varray.count {
                if let v = try DBMgnt.fetch(BasicType.self, .eq(.decimal, varray[vindex].decimal)).first {
                    XCTAssert(v == varray[vindex], "Failed")
                    print("varray[\(vindex)] > checked")
                } else {
                    print("varray[\(vindex)] - deleted")
                }
                vindex += 1
            }
            
            // clear all data
            try DBMgnt.clear(BasicType.self)
        })
    }
    
    func testPerformance() {
        // This is an example of a performance test case.
        
        let tcount = 500

        // clear all first
        tryBlock({
            try DBMgnt.clear(BasicType.self)
        })
        
        var varray = Array<BasicType>()
        while varray.count < tcount {
            varray.append(BasicType.randomValue())
        }
        
        print("start measure multiple times for \(tcount) items")
        
        var s1array = Array<TimeInterval>()
        var s2array = Array<TimeInterval>()
        var s3array = Array<TimeInterval>()
        
        var run_times: TimeInterval = 0
        let start_ti = Date().timeIntervalSince1970
        
        self.measure() {
            
            run_times += 1
            print("start loop: \(run_times)")
            
            let s1 = Date().timeIntervalSince1970
            
            tryBlock({
                try DBMgnt.push(varray)
            })
            
            let s2 = Date().timeIntervalSince1970
            s1array.append(s2 - s1)
        
            tryBlock({
                let _ = try DBMgnt.fetch(BasicType.self)
            })
            
            let s3 = Date().timeIntervalSince1970
            s2array.append(s3 - s2)
        
            tryBlock({
                try DBMgnt.delete(BasicType.self)
            })
            
            let s4 = Date().timeIntervalSince1970
            s3array.append(s4 - s3)
        }
        
        let end_ti = Date().timeIntervalSince1970

        print("end measure, \(tcount) items each loop: \((end_ti - start_ti)/run_times), push: \(s1array._sumDiv(run_times)), fetch: \(s2array._sumDiv(run_times)), delete: \(s3array._sumDiv(run_times))")
    }
}

extension Array where Element == Double {
    
    fileprivate func _sumDiv(_ div: Double) -> Decimal {
        return Decimal(self.reduce(0, { $0 + $1 }) / div)
    }
}
