
# SwiftSQLiteORM

SwiftSQLiteORM is a Swift SQLite ORM Protocol build on [GRDB.swift/SQLCipher](https://github.com/groue/GRDB.swift?tab=readme-ov-file#encryption), will auto create then connect database, create or alter table schema, mapping value between instance property and table column.

## Features

- auto create and connect database file
- auto create or alter table schema relies on table version specified
- support customize table column and property name mapping
- privde convenient filter operator, also support raw SQL expression

## Installation

SwiftSQLiteORM is available through [CocoaPods](https://cocoapods.org). To install
it, simply add the following line to your Podfile:

```ruby
pod 'SwiftSQLiteORM'
```

relies on:

```ruby
  s.dependency 'Runtime'
  s.dependency 'GRDB.swift/SQLCipher'
  s.dependency 'SQLCipher', '~> 4.0'
```

## Usage

### Basic CURD

refers to `testReadmeExample()` in `TestSwiftSQLiteORM.swift`:

```swift
import SwiftSQLiteORM

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
```

### Specify table name & database filename

you can specify table name, or use a seperate database file.

```swift
struct ExampleType: DBTableDef {
    let name: String
    let data: ExampleNested

    typealias ORMKey = Columns

    static var primaryKey: Columns? {
        return .name
    }

    enum Columns: String, DBTableKey {
        case name
        case data
    }

    static var tableName: String {
        return "orm_example_type_t"
    }

    /// schema version for table columns, default 0
    /// - increase version after you add columns
    static var tableVersion: Double {
        return 0.0001
    }

    static var databaseName: String {
        return "orm_example_database.sqlite"
    }

    /// update instance property value created by type reflection
    /// - only ORMKey covered property can restore value from database column
    /// - others property will use default value
    static func ormUpdateNew(_ value: inout ExampleType) -> ExampleType {

    }
}
```

### Filter Options

filter option use `DBRecordFilter` to pass value to SQLite, make calculation or comparison to `ORMKey`, when running `fetch` or `delete`.

SQLite will cast those input value according to column type, before performing calculation or comparison.

supported column types are listed in `DBStoreType`:

- .INTEGER
- .REAL
- .TEXT
- .BLOB

and any custom types confirms to `DBPrimitive` can box value inside `DBStoreValue` when store into database:

- .integer(Int64)
- .real(Double)
- .text(String)
- .blob(Data)

also support optinal property, and column data is nullable.

after table was created in database, `DO NOT` change column type, including optional type, for those property already mapping table column in database.

### Buildin supported ORM types

any ORM types should conforms to `DBPrimitive` or `Codable` protocol, some basic types a buildin support.

```swift
extension Bool: DBPrimitive {}

extension Int: DBPrimitive {}
extension Int8: DBPrimitive {}
extension Int16: DBPrimitive {}
extension Int32: DBPrimitive {}
extension Int64: DBPrimitive {}

extension UInt: DBPrimitive {}
extension UInt8: DBPrimitive {}
extension UInt16: DBPrimitive {}
extension UInt32: DBPrimitive {}
extension UInt64: DBPrimitive {}

extension Float: DBPrimitive {}
extension Double: DBPrimitive {}

extension String: DBPrimitive {}
extension NSString: DBPrimitive {}

extension Data: DBPrimitive {}
extension NSData: DBPrimitive {}

extension NSNumber: DBPrimitive {}
//extension NSDecimalNumber: DBPrimitive {}
extension Decimal: DBPrimitive {}
extension CGFloat: DBPrimitive {}

extension UUID: DBPrimitive {}
extension NSUUID: DBPrimitive {}

// store date as "yyyy-MM-dd HH:mm:ss.SSS" in database, and restore will loss precision
extension Date: DBPrimitive {}
extension NSDate: DBPrimitive {}
```

and the ObjC wrappered type should return mock type in its ormTypeInfo() like `NSString`, `NSNumber` does.

### DBPrimitive protocol

you can add other types conforms to `DBPrimitive`, support store / restore to database, take sturct `URL` for example:

```swift
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
```

so `URL` store string to database, then restore its value from string, for its column type is `.TEXT`.

then you can use `URL` in your struct / class property as other `DBPrimitive` types like `Int`, `String`, which support directly store / restore to database.

more refers to `testDBPrimitiveProtocol()` in `TestSwiftSQLiteORM.swift`.

those complex / nested struct or class which conforms to `Codable` will first encoded as JSON string before store string to database, then restore string to JSON object and mapping dictionary value to instance propertis.

and those complex / nested struct or class also support filter calculation or comparison, according to column type `.TEXT`.

## Test

you can run test in `TestSwiftSQLiteORM.swift`, includnig:

- primitive type CURD
- nested type CURD
- throw invalid property type
- fetch / delete with filter operation
- alter table on tableVersion
- multithreading CURD
- performance

## Encryption

default use GRDB's SQLCipher branch, will auto genearte passphrase for using, then store in KeyChain for next app cold start.

more refers to `DBKeyChain.swift`.

## License

SwiftSQLiteORM also relies on a modified [AnyCoder](https://github.com/pozi119/AnyCoder) source from [SQLiteORM](https://github.com/pozi119/SQLiteORM), and provide its MIT LICENSE under `Codec` folder.

SwiftSQLiteORM is available under the MIT license. See the LICENSE file for more info.
