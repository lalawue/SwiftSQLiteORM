
# SwiftSQLiteORM

SwiftSQLiteORM is a Swift SQLite ORM Protocol build on [GRDB.swift/SQLCipher](https://github.com/groue/GRDB.swift?tab=readme-ov-file#encryption), will auto create then connect database, create or alter table schema, mapping value between instance propertis and table columns.

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

refers to `func testReadmeExample()` in `TestSwiftSQLiteORM.swift`:

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

you can specify table name, or use a seperate database filename.

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

### Supported ORM Types

DBTableDef protocol support `DBPrimitive` or `Codable` type mapping, you can add other type conforms to `DBPrimitive`.

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

### Filter Options

filter option use `DBRecordFilter` to pass value to interface, when running `fetch` or `delete`.

SQLite will cast those input value according to column type, before performing calculation.

supported column types are listed in `DBStoreType`:

- INTEGER
- REAL
- TEXT
- BLOB

and any custom types confirms to `DBPrimitive` can box value inside `DBStoreValue` when store into database:

- integer(Int64)
- real(Double)
- text(String)
- blob(Data)

also support optinal property, and column data is nullable.

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
