# SQLite.swift Documentation

  - [Installation](#installation)
    - [SQLCipher](#sqlcipher)
    - [Frameworkless Targets](#frameworkless-targets)
  - [Getting Started](#getting-started)
    - [Connecting to a Database](#connecting-to-a-database)
      - [Read-Write Databases](#read-write-databases)
      - [Read-Only Databases](#read-only-databases)
      - [In-Memory Databases](#in-memory-databases)
    - [A Note on Thread-Safety](#a-note-on-thread-safety)
  - [Building Type-Safe SQL](#building-type-safe-sql)
    - [Expressions](#expressions)
      - [Compound Expressions](#compound-expressions)
    - [Queries](#queries)
  - [Creating a Table](#creating-a-table)
    - [Create Table Options](#create-table-options)
    - [Column Constraints](#column-constraints)
    - [Table Constraints](#table-constraints)
  - [Inserting Rows](#inserting-rows)
    - [Setters](#setters)
  - [Selecting Rows](#selecting-rows)
    - [Iterating and Accessing Values](#iterating-and-accessing-values)
    - [Plucking Rows](#plucking-rows)
    - [Building Complex Queries](#building-complex-queries)
      - [Selecting Columns](#selecting-columns)
      - [Joining Other Tables](#joining-other-tables)
        - [Column Namespacing](#column-namespacing)
        - [Table Aliasing](#table-aliasing)
      - [Filtering Rows](#filtering-rows)
        - [Filter Operators and Functions](#filter-operators-and-functions)
      - [Sorting Rows](#sorting-rows)
      - [Limiting and Paging Results](#limiting-and-paging-results)
      - [Aggregation](#aggregation)
  - [Updating Rows](#updating-rows)
  - [Deleting Rows](#deleting-rows)
  - [Transactions and Savepoints](#transactions-and-savepoints)
  - [Altering the Schema](#altering-the-schema)
    - [Renaming Tables](#renaming-tables)
    - [Adding Columns](#adding-columns)
      - [Added Column Constraints](#added-column-constraints)
    - [Indexes](#indexes)
      - [Creating Indexes](#creating-indexes)
      - [Dropping Indexes](#dropping-indexes)
    - [Dropping Tables](#dropping-tables)
    - [Migrations and Schema Versioning](#migrations-and-schema-versioning)
  - [Custom Types](#custom-types)
    - [Date-Time Values](#date-time-values)
    - [Binary Data](#binary-data)
    - [Custom Type Caveats](#custom-type-caveats)
  - [Other Operators](#other-operators)
  - [Core SQLite Functions](#core-sqlite-functions)
  - [Aggregate SQLite Functions](#aggregate-sqlite-functions)
  - [Custom SQL Functions](#custom-sql-functions)
  - [Executing Arbitrary SQL](#executing-arbitrary-sql)
  - [Logging](#logging)


[↩]: #sqliteswift-documentation


## Installation

> _Note:_ SQLite.swift requires Swift 1.1 (and [Xcode 6.1](https://developer.apple.com/xcode/downloads/)) or greater.

To install SQLite.swift as an Xcode sub-project:

 1. Drag the **SQLite.xcodeproj** file into your own project. ([Submodule](http://git-scm.com/book/en/Git-Tools-Submodules), clone, or [download](https://github.com/stephencelis/SQLite.swift/archive/master.zip) the project first.)

    ![Installation](Resources/installation@2x.png)

 2. In your target’s **Build Phases**, add **SQLite** to the **Target Dependencies** build phase.

 3. Add **SQLite.framework** to the **Link Binary With Libraries** build phase.

 4. Add **SQLite.framework** to a **Copy Files** build phase with a **Frameworks** destination. (Add a new build phase if need be.)

You should now be able to `import SQLite` from any of your target’s source files and begin using SQLite.swift.


### SQLCipher

To install SQLite.swift with [SQLCipher][] support:

 1. Make sure the **sqlcipher** working copy is checked out in Xcode. If **sqlcipher.xcodeproj** (in the **Vendor** group) is unavailable (and appears red), go to the **Source Control** menu and select **Check Out sqlcipher…** from the **sqlcipher** menu item.

 2. Follow [the instructions above](#installation) with the **SQLiteCipher** target, instead.

[SQLCipher]: http://sqlcipher.net


### Frameworkless Targets

It’s possible to use SQLite.swift in a target that doesn’t support frameworks, including iOS 7 apps and OS X command line tools, though it takes a little extra work.

 1. In your target’s **Build Phases**, add **libsqlite3.dylib** to the **Link Binary With Libraries** build phase.

 2. Copy the SQLite.swift source files (from its **SQLite** directory) into your Xcode project.

 3. Add the following line to your project’s [bridging header](https://developer.apple.com/library/prerelease/ios/documentation/Swift/Conceptual/BuildingCocoaApps/MixandMatch.html#//apple_ref/doc/uid/TP40014216-CH10-XID_79) (a file usually in the form of `$(TARGET_NAME)-Bridging-Header.h`.

    ``` swift
    #import "SQLite-Bridging.h'
    ```

> _Note:_ Adding SQLite.swift source files directly to your application will both remove the `SQLite` module namespace and expose internal functions and variables. Please [report any namespace collisions and bugs](https://github.com/stephencelis/SQLite.swift/issues/new) you encounter.


## Getting Started

To use SQLite.swift classes or structures in your target’s source file, first import the `SQLite` module.

``` swift
import SQLite
```


### Connecting to a Database

Database connections are established using the `Database` class. A database is initialized with a path. SQLite will attempt to create the database file if it does not already exist.

``` swift
let db = Database("path/to/db.sqlite3")
```


#### Read-Write Databases

On iOS, you can create a writable database in your app’s **Documents** directory.

``` swift
let path = NSSearchPathForDirectoriesInDomains(
    .DocumentDirectory, .UserDomainMask, true
).first as String

let db = Database("\(path)/db.sqlite3")
```

On OS X, you can use your app’s **Application Support** directory:

``` swift
var path = NSSearchPathForDirectoriesInDomains(
    .ApplicationSupportDirectory, .UserDomainMask, true
).first as String + NSBundle.mainBundle().bundleIdentifier!

// create parent directory iff it doesn't exist
NSFileManager.defaultManager().createDirectoryAtPath(
    path, withIntermediateDirectories: true, attributes: nil, error: nil
)

let db = Database("\(path)/db.sqlite3")
```


#### Read-Only Databases

If you bundle a database with your app (_i.e._, you’ve copied a database file into your Xcode project and added it to your application target), you can establish a _read-only_ connection to it.

``` swift
let path = NSBundle.mainBundle().pathForResource("db", ofType: "sqlite3")!

let db = Database(path, readonly: true)
```

> _Note_: Signed applications cannot modify their bundle resources. If you bundle a database file with your app for the purpose of bootstrapping, copy it to a writable location _before_ establishing a connection (see [Read-Write Databases](#read-write-databases), above, for typical, writable locations).


#### In-Memory Databases

If you omit the path, SQLite.swift will provision an [in-memory database](https://www.sqlite.org/inmemorydb.html).

``` swift
let db = Database() // equivalent to `Database(":memory:")`
```

To create a temporary, disk-backed database, pass an empty file name.

``` swift
let db = Database("")
```

In-memory databases are automatically deleted when the database connection is closed.


### A Note on Thread-Safety

> _Note:_ Every database comes equipped with its own serial queue for statement execution and can be safely accessed across threads. Threads that open transactions and savepoints, however, do not block other threads from executing statements within the transaction.


## Building Type-Safe SQL

SQLite.swift comes with a typed expression layer that directly maps [Swift types](https://developer.apple.com/library/prerelease/ios/documentation/General/Reference/SwiftStandardLibraryReference/) to their [SQLite counterparts](https://www.sqlite.org/datatype3.html).

| Swift Type      | SQLite Type |
| --------------- | ----------- |
| `Int`           | `INTEGER`   |
| `Double`        | `REAL`      |
| `String`        | `TEXT`      |
| `nil`           | `NULL`      |
| `SQLite.Blob`*  | `BLOB`      |

> *SQLite.swift defines its own `Blob` structure, which safely wraps the underlying bytes.
>
> See [Custom Types](#custom-types) for more information about extending other classes and structures to work with SQLite.swift.

These expressions (in the form of the structure, [`Expression`](#expressions)) build on one another and, with a query ([`Query`](#queries)), can create and execute SQL statements.


### Expressions

Expressions are generic structures associated with a type ([built-in](#building-type-safe-sql) or [custom](#custom-types)), raw SQL, and (optionally) values to bind to that SQL. Typically, you will only explicitly create expressions to describe your columns, and typically only once per column.

``` swift
let id = Expression<Int>("id")
let email = Expression<String>("email")
let balance = Expression<Double>("balance")
let verified = Expression<Bool>("verified")
```

Use optional generics for expressions that can evaluate to `NULL`.

``` swift
let name = Expression<String?>("name")
```

> _Note:_ The default `Expression` initializer is for [quoted identifiers](https://www.sqlite.org/lang_keywords.html) (_i.e._, column names). To build a literal SQL expression, use `init(literal:)`.


### Compound Expressions

Expressions can be combined with other expressions and types using [filters](#filter-operators-and-functions), and [other operators](#other-operators) and [functions](#core-sqlite-functions). These building blocks can create complex SQLite statements.


### Queries

Queries are structures that reference a database and table name, and can be used to build a variety of statements using expressions. We can create a `Query` by subscripting a database connection with a table name.

``` swift
let users = db["users"]
```

Assuming [the table exists](#creating-a-table), we can immediately [insert](#inserting-rows), [select](#selecting-rows), [update](#updating-rows), and [delete](#deleting-rows) rows.


## Creating a Table

We can run [`CREATE TABLE` statements](https://www.sqlite.org/lang_createtable.html) by calling the `create(table:)` function on a database connection. The following is a basic example of SQLite.swift code (using the [expressions](#expressions) and [query](#queries) above) and the corresponding SQL it generates.

``` swift
db.create(table: users) { t in     // CREATE TABLE "users" (
    t.column(id, primaryKey: true) //     "id" INTEGER PRIMARY KEY NOT NULL,
    t.column(email, unique: true)  //     "email" TEXT UNIQUE NOT NULL,
    t.column(name)                 //     "name" TEXT
}                                  // )
```

> _Note:_ `Expression<T>` structures (in this case, the `id` and `email` columns), generate `NOT NULL` constraints automatically, while `Expression<T?>` structures (`name`) do not.


### Create Table Options

The `create(table:)` function has several default parameters we can override.

  - `temporary` adds a `TEMPORARY` clause to the `CREATE TABLE` statement (to create a temporary table that will automatically drop when the database connection closes). Default: `false`.

    ``` swift
    db.create(table: users, temporary: true) { t in /* ... */ }
    // CREATE TEMPORARY TABLE "users" -- ...
    ```

  - `ifNotExists` adds an `IF NOT EXISTS` clause to the `CREATE TABLE` statement (which will bail out gracefully if the table already exists). Default: `false`.

    ``` swift
    db.create(table: users, ifNotExists: true) { t in /* ... */ }
    // CREATE TABLE "users" IF NOT EXISTS -- ...
    ```

### Column Constraints

The `column` function is used for a single column definition. It takes an [expression](#expressions) describing the column name and type, and accepts several parameters that map to various column constraints and clauses.

  - `primaryKey` adds an `INTEGER PRIMARY KEY` constraint to a single column. (See the `primaryKey` function under [Table Constraints](#table-constraints) for non-integer primary keys).

    ``` swift
    t.column(id, primaryKey: true)
    // "id" INTEGER PRIMARY KEY NOT NULL
    ```

    > _Note:_ The `primaryKey` parameter cannot be used alongside `defaultValue` or `references`. If you need to create a column that has a default value and is also a primary and/or foreign key, use the `primaryKey` and `foreignKey` functions mentioned under [Table Constraints](#table-constraints).
    >
    > Primary keys cannot be optional (`Expression<Int?>`).

  - `unique` adds a `UNIQUE` constraint to the column. (See the `unique` function under [Table Constraints](#table-constraints) for uniqueness over multiple columns).

    ``` swift
    t.column(email, unique: true)
    // "email" TEXT UNIQUE NOT NULL
    ```

  - `check` attaches a `CHECK` constraint to a column definition in the form of a boolean expression (`Expression<Bool>`). Boolean expressions can be easily built using [filter operators and functions](#filter-operators-and-functions). (See also the `check` function under [Table Constraints](#table-constraints).)

    ``` swift
    t.column(email, check: like("%@%", email))
    // "email" TEXT NOT NULL CHECK ("email" LIKE '%@%')
    ```

  - `defaultValue` adds a `DEFAULT` clause to a column definition and _only_ accepts a value (or expression) matching the column’s type. This value is used if none is explicitly provided during [an `INSERT`](#inserting-rows).

    ``` swift
    t.column(name, defaultValue: "Anonymous")
    // "name" TEXT DEFAULT 'Anonymous'
    ```

    > _Note:_ The `defaultValue` parameter cannot be used alongside `primaryKey` and `references`. If you need to create a column that has a default value and is also a primary and/or foreign key, use the `primaryKey` and `foreignKey` functions mentioned under [Table Constraints](#table-constraints).

  - `collate` adds a `COLLATE` clause to `Expression<String>` (and `Expression<String?>`) column definitions with [a collating sequence](https://www.sqlite.org/datatype3.html#collation) defined in the `Collation` enumeration.

    ``` swift
    t.column(email, collate: .NoCase)
    // "email" TEXT NOT NULL COLLATE "NOCASE"
    ```

  - `references` adds a `REFERENCES` clause to `Expression<Int>` (and `Expression<Int?>`) column definitions and accepts a table (`Query`) or namespaced column expression. (See the `foreignKey` function under [Table Constraints](#table-constraints) for non-integer foreign key support.)

    ``` swift
    t.column(user_id, references: users[id])
    // "user_id" INTEGER REFERENCES "users"("id")

    t.column(user_id, references: users)
    // "user_id" INTEGER REFERENCES "users"
    // -- assumes "users" has a PRIMARY KEY
    ```

    > _Note:_ The `references` parameter cannot be used alongside `primaryKey` and `defaultValue`. If you need to create a column that has a default value and is also a primary and/or foreign key, use the `primaryKey` and `foreignKey` functions mentioned under [Table Constraints](#table-constraints).


### Table Constraints

Additional constraints may be provided outside the scope of a single column using the following functions.

  - `primaryKey` adds a `PRIMARY KEY` constraint to the table. Unlike [the column constraint, above](#column-constraints), it supports all SQLite types, [ascending and descending orders](#sorting-rows), and composite (multiple column) keys.

    ``` swift
    t.primaryKey(email.asc, name)
    // PRIMARY KEY("email" ASC, "name")
    ```

  - `unique` adds a `UNIQUE` constraint to the table. Unlike [the column constraint, above](#column-constraints), it supports composite (multiple column) constraints.

    ``` swift
    t.unique(local, domain)
    // UNIQUE("local", "domain")
    ```

  - `check` adds a `CHECK` constraint to the table in the form of a boolean expression (`Expression<Bool>`). Boolean expressions can be easily built using [filter operators and functions](#filter-operators-and-functions). (See also the `check` parameter under [Column Constraints](#column-constraints).)

    ``` swift
    t.check(balance >= 0)
    // CHECK ("balance" >= 0.0)
    ```

  - `foreignKey` adds a `FOREIGN KEY` constraint to the table. Unlike [the `references` constraint, above](#column-constraints), it supports all SQLite types, and both [`ON UPDATE` and `ON DELETE` actions](https://www.sqlite.org/foreignkeys.html#fk_actions), and composite (multiple column) keys.

    ``` swift
    t.foreignKey(user_id, on: users[id], delete: .SetNull)
    // FOREIGN KEY("user_id") REFERENCES "users"("id") ON DELETE SET NULL
    ```

<!-- TODO
### Creating a Table from a Select Statement
-->


## Inserting Rows

We can insert rows into a table by calling a [query’s](#queries) `insert` function with a list of [setters](#setters), typically [typed column expressions](#expressions) and values (which can also be expressions), each joined by the `<-` operator.

``` swift
users.insert(email <- "alice@mac.com", name <- "Alice")?
// INSERT INTO "users" ("email", "name") VALUES ('alice@mac.com', 'Alice')
```

The `insert` function can return several different types that are useful in different contexts.

  - An `Int?` representing the inserted row’s [`ROWID`][ROWID] (or `nil` on failure), for simplicity.

    ``` swift
    if let insertId = users.insert(email <- "alice@mac.com") {
        println("inserted id: \(insertId)")
    }
    ```

    We can use the optional nature of the value to disambiguate with a simple `?` or `!`.

    ``` swift
    // ignore failure
    users.insert(email <- "alice@mac.com")?

    // assertion on failure
    users.insert(email <- "alice@mac.com")!
    ```

  - A `Statement`, for [the transaction and savepoint helpers](#transactions-and-savepoints) that take a list of statements.

    ``` swift
    db.transaction(
        users.insert(email <- "alice@mac.com"),
        users.insert(email <- "betty@mac.com")
    )
    // BEGIN DEFERRED TRANSACTION;
    // INSERT INTO "users" ("email") VALUES ('alice@mac.com');
    // INSERT INTO "users" ("email") VALUES ('betty@mac.com');
    // COMMIT TRANSACTION;
    ```

  - A tuple of the above [`ROWID`][ROWID] and statement: `(id: Int?, statement: Statement)`, for flexibility.

    ``` swift
    let (id, statement) = users.insert(email <- "alice@mac.com")
    if let id = id {
        println("inserted id: \(id)")
    } else if statement.failed {
        println("insertion failed: \(statement.reason)")
    }
    ```

The [`update`](#updating-rows) and [`delete`](#deleting-rows) functions follow similar patterns.

> _Note:_ If `insert` is called without any arguments, the statement will run with a `DEFAULT VALUES` clause. The table must not have any constraints that aren’t fulfilled by default values.
>
> ``` swift
> timestamps.insert()!
> // INSERT INTO "timestamps" DEFAULT VALUES
> ```


### Setters

SQLite.swift typically uses the `<-` operator to set values during [inserts](#inserting-rows) and [updates](#updating-rows).

``` swift
views.update(count <- 0)
// UPDATE "views" SET "count" = 0 WHERE ("id" = 1)
```

There are also a number of convenience setters that take the existing value into account using native Swift operators.

For example, to atomically increment a column, we can use `++`:

``` swift
views.update(count++) // equivalent to `views.update(count -> count + 1)`
// UPDATE "views" SET "count" = "count" + 1 WHERE ("id" = 1)
```

To take an amount and “move” it via transaction, we can use `-=` and `+=`:

``` swift
let amount = 100.0
db.transaction(
    alice.update(balance -= amount),
    betty.update(balance += amount)
)
// BEGIN DEFERRED TRANSACTION;
// UPDATE "users" SET "balance" = "balance" - 100.0 WHERE ("id" = 1);
// UPDATE "users" SET "balance" = "balance" + 100.0 WHERE ("id" = 2);
// COMMIT TRANSACTION;
```


###### Infix Setters

| Operator | Types              |
| -------- | ------------------ |
| `<-`     | `Value -> Value`   |
| `+=`     | `Number -> Number` |
| `-=`     | `Number -> Number` |
| `*=`     | `Number -> Number` |
| `/=`     | `Number -> Number` |
| `%=`     | `Int -> Int`       |
| `<<=`    | `Int -> Int`       |
| `>>=`    | `Int -> Int`       |
| `&=`     | `Int -> Int`       |
| `||=`    | `Int -> Int`       |
| `^=`     | `Int -> Int`       |
| `+=`     | `String -> String` |


###### Postfix Setters

| Operator | Types        |
| -------- | ------------ |
| `++`     | `Int -> Int` |
| `--`     | `Int -> Int` |


## Selecting Rows

[`Query` structures](#queries) are `SELECT` statements waiting to happen. They execute via [iteration](#iterating-and-accessing-values) and [other means](#plucking-values) of sequence access.


### Iterating and Accessing Values

[Queries](#queries) execute lazily upon iteration. Each row is returned as a `Row` object, which can be subscripted with a [column expression](#expressions) matching one of the columns returned.

``` swift
for user in users {
    println("id: \(user[id]), email: \(user[email]), name: \(user[name])")
    // id: 1, email: alice@mac.com, name: Optional("Alice")
}
// SELECT * FROM "users"
```

`Expression<T>` column values are _automatically unwrapped_ (we’ve made a promise to the compiler that they’ll never be `NULL`), while `Expression<T?>` values remain wrapped.


### Plucking Rows

We can pluck the first row by calling the `first` computed property on [`Query`](#queries).

``` swift
if let user = users.first { /* ... */ } // Row
// SELECT * FROM "users" LIMIT 1
```

To collect all rows into an array, we can simply wrap the sequence (though this is not always the most memory-efficient idea).

``` swift
let all = Array(users)
// SELECT * FROM "users"
```


### Building Complex Queries

[`Query`](#queries) structures have a number of chainable functions that can be used (with [expressions](#expressions)) to add and modify [a number of clauses](https://www.sqlite.org/lang_select.html) to the underlying statement.

``` swift
let query = users.select(email)           // SELECT "email" FROM "users"
                 .filter(name != nil)     // WHERE "name" IS NOT NULL
                 .order(email.desc, name) // ORDER BY "email" DESC, "name"
                 .limit(5, offset: 1)     // LIMIT 5 OFFSET 1
```


#### Selecting Columns

By default, [`Query`](#queries) objects select every column of the result set (using `SELECT *`). We can use the `select` function with a list of [expressions](#expressions) to return specific columns instead.

``` swift
let query = users.select(id, email)
// SELECT "id", "email" FROM "users"
```

<!-- TODO
We can select aggregate values using [aggregate functions](#aggregate-sqlite-functions).

``` swift
let query = users.select(count(*))
// SELECT count(*) FROM "users"
```
-->


#### Joining Other Tables

We can join tables using a [query’s](#queries) `join` function.

``` swift
users.join(posts, on: user_id == users[id])
// SELECT * FROM "users" INNER JOIN "posts" ON ("user_id" = "users"."id")
```

The `join` function takes a [query](#queries) object (for the table being joined on), a join condition (`on`), and is prefixed with an optional join type (default: `.Inner`). Join conditions can be built using [filter operators and functions](#filter-operators-and-functions), generally require [namespacing](#column-namespacing), and sometimes require [aliasing](#table-aliasing).


##### Column Namespacing

When joining tables, column names can become ambiguous. _E.g._, both tables may have an `id` column.

``` swift
let query = users.join(posts, on: user_id == id)
// assertion failure: ambiguous column 'id'
```

We can disambiguate by namespacing `id`.

``` swift
let query = users.join(posts, on: user_id == users[id])
// SELECT * FROM "users" INNER JOIN "posts" ON ("user_id" = "users"."id")
```

Namespacing is achieved by subscripting a [query](#queries) with a [column expression](#expressions) (_e.g._, `users[id]` above becomes `users.id`).

> _Note:_ We can namespace all of a table’s columns using `*`.
>
> ``` swift
> let query = users.select(users[*])
> // SELECT "users".* FROM "users"
> ```


##### Table Aliasing

Occasionally, we need to join a table to itself, in which case we must alias the table with another name. We can achieve this using the [query’s](#queries) `alias` function.

``` swift
let managers = users.alias("managers")

let query = users.join(managers, on: managers[id] == users[manager_id])
// SELECT * FROM "users"
// INNER JOIN "users" AS "managers" ON ("managers"."id" = "users"."manager_id")
```

If query results can have ambiguous column names, row values should be accessed with namespaced [column expressions](#expressions). In the above case, `SELECT *` immediately namespaces all columns of the result set.

``` swift
let user = query.first!
user[id]           // fatal error: ambiguous column 'id'
                   // (please disambiguate: ["users"."id", "managers"."id"])

user[users[id]]    // returns "users"."id"
user[managers[id]] // returns "managers"."id"
```


#### Filtering Rows

SQLite.swift filters rows using a [query’s](#queries) `filter` function with a boolean [expression](#expressions) (`Expression<Bool>`).

``` swift
users.filter(id == 1)
// SELECT * FROM "users" WHERE ("id" = 1)

users.filter(contains([1, 2, 3, 4, 5], id))
// SELECT * FROM "users" WHERE ("id" IN (1, 2, 3, 4, 5))

users.filter(like("%@mac.com", email))
// SELECT * FROM "users" WHERE ("email" LIKE '%@mac.com')

users.filter(verified && lower(name) == "alice")
// SELECT * FROM "users" WHERE ("verified" AND (lower("name") == 'alice'))

users.filter(verified || balance >= 10_000)
// SELECT * FROM "users" WHERE ("verified" OR ("balance" >= 10000.0))
```

You can build your own boolean expressions by using one of the many [filter operators and functions](#filter-operators-and-functions).

> _Note:_ SQLite.swift defines `filter` instead of `where` because `where` is [a reserved keyword](https://developer.apple.com/library/ios/documentation/swift/conceptual/Swift_Programming_Language/LexicalStructure.html#//apple_ref/doc/uid/TP40014097-CH30-XID_906).


##### Filter Operators and Functions

SQLite.swift defines a number of operators for building filtering predicates. Operators and functions work together in a type-safe manner, so attempting to equate or compare different types will prevent compilation.


###### Infix Filter Operators

| Swift | Types                            | SQLite         |
| ----- | -------------------------------- | -------------- |
| `==`  | `Equatable -> Bool`              | `=`/`IS`*      |
| `!=`  | `Equatable -> Bool`              | `!=`/`IS NOT`* |
| `>`   | `Comparable -> Bool`             | `>`            |
| `>=`  | `Comparable -> Bool`             | `>=`           |
| `<`   | `Comparable -> Bool`             | `<`            |
| `<=`  | `Comparable -> Bool`             | `<=`           |
| `~=`  | `(Interval, Comparable) -> Bool` | `BETWEEN`      |
| `&&`  | `Bool -> Bool`                   | `AND`          |
| `||`  | `Bool -> Bool`                   | `OR`           |

> *When comparing against `nil`, SQLite.swift will use `IS` and `IS NOT` accordingly.


###### Prefix Filter Operators

| Swift | Types              | SQLite |
| ----- | ------------------ | ------ |
| `!`   | `Bool -> Bool`     | `NOT`  |


###### Filtering Functions

| Swift      | Types                   | SQLite  |
| ---------- | ----------------------- | ------- |
| `like`     | `String -> Bool`        | `LIKE`  |
| `glob`     | `String -> Bool`        | `GLOB`  |
| `match`    | `String -> Bool`        | `MATCH` |
| `contains` | `(Array<T>, T) -> Bool` | `IN`    |


<!-- TODO
#### Grouping Results
-->


#### Sorting Rows

We can pre-sort returned rows using the [query’s](#queries) `order` function.

_E.g._, to return users sorted by `email`, then `name`, in ascending order:

``` swift
users.order(email, name)
// SELECT * FROM "users" ORDER BY "email", "name"
```

The `order` function takes a list of [column expressions](#expressions).

`Expression` objects have two computed properties to assist sorting: `asc` and `desc`. These properties append the expression with `ASC` and `DESC` to mark ascending and descending order respectively.

``` swift
users.order(email.desc, name.asc)
// SELECT * FROM "users" ORDER BY "email" DESC, "name" ASC
```


#### Limiting and Paging Results

We can limit and skip returned rows using a [query’s](#queries) `limit` function (and its optional `offset` parameter).

``` swift
users.limit(5)
// SELECT * FROM "users" LIMIT 5

users.limit(5, offset: 5)
// SELECT * FROM "users" LIMIT 5 OFFSET 5
```


#### Aggregation

[`Query`](#queries) structures come with a number of functions that quickly return aggregate values from the table. These mirror the [core aggregate functions](#aggregate-sqlite-functions) and are executed immediately against the query.

``` swift
users.count
// SELECT count(*) FROM "users"
```

Filtered queries will appropriately filter aggregate values.

``` swift
users.filter(name != nil).count
// SELECT count(*) FROM "users" WHERE "name" IS NOT NULL
```

  - `count` as a computed property (see examples above) returns the total number of rows matching the query.

    `count` as a function takes a [column name](#expressions) and returns the total number of rows where that column is not `NULL`.

    ``` swift
    users.count(name) // -> Int
    // SELECT count("name") FROM "users"
    ```

  - `max` takes a comparable column expression and returns the largest value if any exists.

    ``` swift
    users.max(id) // -> Int?
    // SELECT max("id") FROM "users"
    ```

  - `min` takes a comparable column expression and returns the smallest value if any exists.

    ``` swift
    users.min(id) // -> Int?
    // SELECT min("id") FROM "users"
    ```

  - `average` takes a numeric column expression and returns the average row value (as a `Double`) if any exists.

    ``` swift
    users.average(balance) // -> Double?
    // SELECT avg("balance") FROM "users"
    ```

  - `sum` takes a numeric column expression and returns the sum total of all rows if any exist.

    ``` swift
    users.sum(balance) // -> Double?
    // SELECT sum("balance") FROM "users"
    ```

  - `total`, like `sum`, takes a numeric column expression and returns the sum total of all rows, but in this case always returns a `Double`, and returns `0.0` for an empty query.

    ``` swift
    users.total(balance) // -> Double
    // SELECT total("balance") FROM "users"
    ```

> _Note:_ Most of the above aggregate functions (except `max` and `min`) can be called with a `distinct` parameter to aggregate `DISTINCT` values only.
>
> ``` swift
> users.count(distinct: name)
> // SELECT count(DISTINCT "name") FROM "users"
> ```


## Updating Rows

We can update a table’s rows by calling a [query’s](#queries) `update` function with a list of [setters](#setters), typically [typed column expressions](#expressions) and values (which can also be expressions), each joined by the `<-` operator.

When an unscoped query calls `update`, it will update _every_ row in the table.

``` swift
users.update(email <- "alice@me.com")?
// UPDATE "users" SET "email" = 'alice@me.com'
```

Be sure to scope `UPDATE` statements beforehand using [the `filter` function](#filtering-rows).

``` swift
let alice = users.filter(id == 1)
alice.update(email <- "alice@me.com")?
// UPDATE "users" SET "email" = 'alice@me.com' WHERE ("id" = 1)
```

Like [`insert`](#inserting-rows) (and [`delete`](#updating-rows)), `update` can return several different types that are useful in different contexts.

  - An `Int?` representing the number of updated rows (or `nil` on failure), for simplicity.

    ``` swift
    if alice.update(email <- "alice@me.com") > 0 {
        println("updated Alice")
    }
    ```

    We can use the optional nature of the value to disambiguate with a simple `?` or `!`.

    ``` swift
    // ignore failure
    alice.update(email <- "alice@me.com")?

    // assertion on failure
    alice.update(email <- "alice@me.com")!
    ```

  - A `Statement`, for [the transaction and savepoint helpers](#transactions-and-savepoints) that take a list of statements.

  - A tuple of the above number of updated rows and statement: `(changes: Int?, Statement)`, for flexibility.


## Deleting Rows

We can delete rows from a table by calling a [query’s](#queries) `delete` function.

When an unscoped query calls `delete`, it will delete _every_ row in the table.

``` swift
users.delete()?
// DELETE FROM "users"
```

Be sure to scope `DELETE` statements beforehand using [the `filter` function](#filtering-rows).

``` swift
let alice = users.filter(id == 1)
alice.delete()?
// DELETE FROM "users" WHERE ("id" = 1)
```

Like [`insert`](#inserting-rows) and [`update`](#updating-rows), `delete` can return several different types that are useful in different contexts.

  - An `Int?` representing the number of deleted rows (or `nil` on failure), for simplicity.

    ``` swift
    if alice.delete() > 0 {
        println("deleted Alice")
    }
    ```

    We can use the optional nature of the value to disambiguate with a simple `?` or `!`.

    ``` swift
    // ignore failure
    alice.delete()?

    // assertion on failure
    alice.delete()!
    ```

  - A `Statement`, for [the transaction and savepoint helpers](#transactions-and-savepoints) that take a list of statements.

  - A tuple of the above number of deleted rows and statement: `(changes: Int?, Statement)`, for flexibility.


## Transactions and Savepoints

Using the `transaction` and `savepoint` functions, we can run a series of statements, commiting the changes to the database if they all succeed. If a single statement fails, we bail out early and roll back.

``` swift
db.transaction(
    users.insert(email <- "betty@icloud.com"),
    users.insert(email <- "cathy@icloud.com", manager_id <- db.lastId)
)
```

> _Note:_ Each statement is captured in an auto-closure and won’t execute till the preceding statement succeeds. This means we can use the `lastId` property on `Database` to reference the previous statement’s insert [`ROWID`][ROWID].


## Altering the Schema

SQLite.swift comes with several functions (in addition to `create(table:)`) for altering a database schema in a type-safe manner.


### Renaming Tables

We can rename a table by calling the `rename(table:to:)` function on a database connection.

``` swift
db.rename(users, to: "users_old")
// ALTER TABLE "users" RENAME TO "users_old"
```


### Adding Columns

We can add columns to a table by calling `alter` function on a database connection. SQLite.swift enforces [the same limited subset](https://www.sqlite.org/lang_altertable.html) of `ALTER TABLE` that SQLite supports.

``` swift
db.alter(table: users, add: suffix)
// ALTER TABLE "users" ADD COLUMN "suffix" TEXT
```


#### Added Column Constraints

The `alter` function shares several of the same [`column` function parameters](#column-constraints) used when [creating tables](#creating-a-table).

  - `check` attaches a `CHECK` constraint to a column definition in the form of a boolean expression (`Expression<Bool>`). (See also the `check` function under [Table Constraints](#table-constraints).)

    ``` swift
    let check = contains(["JR", "SR"], suffix)
    db.alter(table: users, add: suffix, check: check)
    // ALTER TABLE "users"
    // ADD COLUMN "suffix" TEXT CHECK ("suffix" IN ('JR', 'SR'))
    ```

  - `defaultValue` adds a `DEFAULT` clause to a column definition and _only_ accepts a value matching the column’s type. This value is used if none is explicitly provided during [an `INSERT`](#inserting-rows).

    ``` swift
    db.alter(table: users, add: suffix, defaultValue: "SR")
    // ALTER TABLE "users" ADD COLUMN "suffix" TEXT DEFAULT 'SR'
    ```

    > _Note:_ Unlike the [`CREATE TABLE` constraint](#table-constraints), default values may not be expression structures (including `CURRENT_TIME`, `CURRENT_DATE`, or `CURRENT_TIMESTAMP`).

  - `collate` adds a `COLLATE` clause to `Expression<String>` (and `Expression<String?>`) column definitions with [a collating sequence](https://www.sqlite.org/datatype3.html#collation) defined in the `Collation` enumeration.

    ``` swift
    t.column(email, collate: .NoCase)
    // email TEXT NOT NULL COLLATE "NOCASE"
    ```

  - `references` adds a `REFERENCES` clause to `Int` (and `Int?`) column definitions and accepts a table or namespaced column expression. (See the `foreignKey` function under [Table Constraints](#table-constraints) for non-integer foreign key support.)

    ``` swift
    db.alter(table: posts, add: user_id, references: users[id])
    // ALTER TABLE "posts" ADD COLUMN "user_id" INTEGER REFERENCES "users"("id")

    db.alter(table: posts, add: user_id, references: users)
    // ALTER TABLE "posts" ADD COLUMN "user_id" INTEGER REFERENCES "users"
    // -- assumes "users" has a PRIMARY KEY
    ```


### Indexes


#### Creating Indexes

We can run [`CREATE INDEX` statements](https://www.sqlite.org/lang_createindex.html) by calling the `create(index:)` function on a database connection.

``` swift
db.create(index: users, on: email)
// CREATE INDEX "index_users_on_email" ON "users" ("email")
```

The index name is generated automatically based on the table and column names.

The `create(index:)` function has a couple default parameters we can override.

  - `unique` adds a `UNIQUE` constraint to the index. Default: `false`.

    ``` swift
    db.create(index: users, on: email, unique: true)
    // CREATE UNIQUE INDEX "index_users_on_email" ON "users" ("email")
    ```

  - `ifNotExists` adds an `IF NOT EXISTS` clause to the `CREATE TABLE` statement (which will bail out gracefully if the table already exists). Default: `false`.

    ``` swift
    db.create(index: users, on: email, ifNotExists: true)
    // CREATE INDEX IF NOT EXISTS "index_users_on_email" ON "users" ("email")
    ```


#### Dropping Indexes

We can run [`DROP INDEX` statements](https://www.sqlite.org/lang_dropindex.html) by calling the `drop(index:)` function on a database connection.

``` swift
db.drop(index: users, on: email)
// DROP INDEX "index_users_on_email"
```

The `drop(index:)` function has one additional parameter, `ifExists`, which (when `true`) adds an `IF EXISTS` clause to the statement.

``` swift
db.drop(index: users, on: email, ifExists: true)
// DROP INDEX IF EXISTS "index_users_on_email"
```


### Dropping Tables

We can run [`DROP TABLE` statements](https://www.sqlite.org/lang_droptable.html) by calling the `drop(table:)` function on a database connection.

``` swift
db.drop(table: users)
// DROP TABLE "users"
```

The `drop(table:)` function has one additional parameter, `ifExists`, which (when `true`) adds an `IF EXISTS` clause to the statement.

``` swift
db.drop(table: users, ifExists: true)
// DROP TABLE IF EXISTS "users"
```


### Migrations and Schema Versioning

SQLite.swift provides a convenience property on `Database` to query and set the [`PRAGMA user_version`](https://sqlite.org/pragma.html#pragma_schema_version). This is a great way to manage your schema’s version over migrations.

``` swift
if db.userVersion == 0 {
    // handle first migration
    db.userVersion = 1
}
if db.userVersion == 1 {
    // handle second migration
    db.userVersion = 2
}
```


## Custom Types

SQLite.swift supports serializing and deserializing any custom type as long as it conforms to the `Value` protocol.

> ``` swift
> protocol Value {
>     typealias Datatype: Binding
>     class var declaredDatatype: String { get }
>     class func fromDatatypeValue(datatypeValue: Datatype) -> Self
>     var datatypeValue: Datatype { get }
> }
> ```

The `Datatype` must be one of the basic Swift types that values are bridged through before serialization and deserialization (see [Building Type-Safe SQL](#building-type-safe-sql) for a list of types).

> _Note:_ `Binding` is a protocol that SQLite.swift uses internally to directly map SQLite types to Swift types. **Do _not_** conform custom types to the `Binding` protocol.

Once extended, the type can be used [_almost_](#custom-type-caveats) wherever typed expressions can be.


### Date-Time Values

In SQLite, `DATETIME` columns can be treated as strings or numbers, so we can transparently bridge `NSDate` objects through Swift’s `String` or `Int` types.

To serialize `NSDate` objects as `TEXT` values (in ISO 8601), we’ll use `String`.

``` swift
extension NSDate: Value {
    class var declaredDatatype: String {
        return String.declaredDatatype
    }
    class func fromDatatypeValue(stringValue: String) -> NSDate {
        return SQLDateFormatter.dateFromString(stringValue)!
    }
    var datatypeValue: String {
        return SQLDateFormatter.stringFromDate(self)
    }
}

let SQLDateFormatter: NSDateFormatter = {
    let formatter = NSDateFormatter()
    formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSS"
    formatter.locale = NSLocale(localeIdentifier: "en_US_POSIX")
    formatter.timeZone = NSTimeZone(forSecondsFromGMT: 0)
    return formatter
}()
```

We can also treat them as `INTEGER` values using `Int`.

``` swift
extension NSDate: Value {
    class var declaredDatatype: String {
        return Int.declaredDatatype
    }
    class func fromDatatypeValue(intValue: Int) -> Self {
        return self(timeIntervalSince1970: NSTimeInterval(intValue))
    }
    var datatypeValue: Int {
        return Int(timeIntervalSince1970)
    }
}
```

> _Note:_ SQLite’s `CURRENT_DATE`, `CURRENT_TIME`, and `CURRENT_TIMESTAMP` helpers return `TEXT` values. Because of this (and the fact that Unix time is far less human-readable when we’re faced with the raw data), we recommend using the `TEXT` extension.

Once defined, we can use these types directly in SQLite statements.

``` swift
let published_at = Expression<NSDate>("published_at")

let published = posts.filter(published_at <= NSDate())
// extension where Datatype == String:
//     SELECT * FROM "posts" WHERE "published_at" <= '2014-11-18 12:45:30'
// extension where Datatype == Int:
//     SELECT * FROM "posts" WHERE "published_at" <= 1416314730
```


### Binary Data

Any object that can be encoded and decoded can be stored as a blob of data in SQL.

We can create an `NSData` bridge rather trivially.

``` swift
extension NSData: Value {
    class var declaredDatatype: String {
        return Blob.declaredDatatype
    }
    class func fromDatatypeValue(blobValue: Blob) -> Self {
        return self(bytes: blobValue.bytes, length: blobValue.length)
    }
    var datatypeValue: Blob {
        return Blob(bytes: bytes, length: length)
    }
}
```

We can bridge any type that can be initialized from and encoded to `NSData`.

``` swift
// assumes NSData conformance, above
extension UIImage: Value {
    class var declaredDatatype: String {
        return NSData.declaredDatatype
    }
    class func fromDatatypeValue(blobValue: Blob) -> Self {
        return self(data: NSData.fromDatatypeValue(blobValue))
    }
    var datatypeValue: Blob {
        return UIImagePNGRepresentation(self).datatypeValue
    }
}
```

> _Note:_ See the [Archives and Serializations Programming Guide](https://developer.apple.com/library/ios/documentation/Cocoa/Conceptual/Archiving/Archiving.html#//apple_ref/doc/uid/10000047i) for more information on encoding and decoding custom types.


### Custom Type Caveats

Swift does _not_ currently support generic subscripting, which means we cannot, by default, subscript Expressions with custom types to:

 1. **Namespace expressions**. Use the `namespace` function, instead:

    ``` swift
    let avatar = Expression<UIImage?>("avatar")
    users[avatar]           // fails to compile
    users.namespace(avatar) // "users"."avatar"
    ```

 2. **Access column data**. Use the `get` function, instead:

    ``` swift
    let user = users.first!
    user[avatar]            // fails to compile
    user.get(avatar)        // UIImage?
    ```

We can, of course, write extensions, but they’re rather wordy.

``` swift
extension Query {
    subscript(column: Expression<UIImage>) -> Expression<UIImage> {
        return namespace(column)
    }
    subscript(column: Expression<UIImage?>) -> Expression<UIImage?> {
        return namespace(column)
    }
}

extension Row {
    subscript(column: Expression<UIImage>) -> UIImage {
        return get(column)
    }
    subscript(column: Expression<UIImage?>) -> UIImage? {
        return get(column)
    }
}
```


## Other Operators

In addition to [filter operators](#filtering-infix-operators), SQLite.swift defines a number of operators that can modify expression values with arithmetic, bitwise operations, and concatenation.


###### Other Infix Operators

| Swift | Types                            | SQLite   |
| ----- | -------------------------------- | -------- |
| `+`   | `Number -> Number`               | `+`      |
| `-`   | `Number -> Number`               | `-`      |
| `*`   | `Number -> Number`               | `*`      |
| `/`   | `Number -> Number`               | `/`      |
| `%`   | `Int -> Int`                     | `%`      |
| `<<`  | `Int -> Int`                     | `<<`     |
| `>>`  | `Int -> Int`                     | `>>`     |
| `&`   | `Int -> Int`                     | `&`      |
| `|`   | `Int -> Int`                     | `|`      |
| `+`   | `String -> String`               | `||`     |

> _Note:_ SQLite.swift also defines a bitwise XOR operator, `^`, which expands the expression `lhs ^ rhs` to `~(lhs & rhs) & (lhs | rhs)`.


###### Other Prefix Operators

| Swift | Types              | SQLite |
| ----- | ------------------ | ------ |
| `~`   | `Int -> Int`       | `~`    |
| `-`   | `Number -> Number` | `-`    |


## Core SQLite Functions

Many of SQLite’s [core functions](https://www.sqlite.org/lang_corefunc.html) have been surfaced in and type-audited for SQLite.swift.

> _Note:_ SQLite.swift aliases the `??` operator to the `ifnull` function.
>
> ``` swift
> name ?? email // ifnull("name", "email")
> ```


## Aggregate SQLite Functions

Most of SQLite’s [aggregate functions](https://www.sqlite.org/lang_aggfunc.html) have been surfaced in and type-audited for SQLite.swift.


## Custom SQL Functions

We can create custom SQL functions by calling `create(function:)` on a database connection.

For example, to give queries access to [`MobileCoreServices.UTTypeConformsTo`](https://developer.apple.com/library/ios/documentation/MobileCoreServices/Reference/UTTypeRef/index.html#//apple_ref/c/func/UTTypeConformsTo), we can write the following:

``` swift
import MobileCoreServices

let typeConformsTo: (String, Expression<String>) -> Expression<Bool> = (
    db.create(function: "typeConformsTo", deterministic: true) { UTI, conformsToUTI in
        return UTTypeConformsTo(UTI, conformsToUTI) != 0
    }
)
```

> _Note:_ The optional `deterministic` parameter is an optimization that causes the function to be created with [`SQLITE_DETERMINISTIC`](https://www.sqlite.org/c3ref/create_function.html).

Note `typeConformsTo`’s signature:

``` swift
(Expression<String>, String) -> Expression<Bool>
```

Because of this, `create(function:)` expects a block with the following signature:

``` swift
(String, String) -> Bool
```

Once assigned, the closure can be called wherever boolean expressions are accepted.

``` swift
let attachments = db["attachments"]
let UTI = Expression<String>("UTI")

attachments.filter(typeConformsTo(UTI, kUTTypeImage))
// SELECT * FROM "attachments" WHERE "typeConformsTo"("UTI", 'public.image')
```

> _Note:_ The return type of a function must be [a core SQL type](#building-type-safe-sql) or [conform to `Value`](#custom-types).

You can create loosely-typed functions by handling an array of raw arguments, instead.

``` swift
db.create(function: "typeConformsTo", deterministic: true) { args in
    switch (args[0], args[1]) {
    case let (UTI as String, conformsToUTI as String):
        return Int(UTTypeConformsTo(UTI, conformsToUTI))
    default:
        return nil
    }
}
```

Creating a loosely-typed function cannot return a closure and instead must be wrapped manually or executed [using raw SQL](#executing-arbitrary-sql).

``` swift
let stmt = db.prepare("SELECT * FROM attachments WHERE typeConformsTo(UTI, ?)")
for row in stmt.bind(kUTTypeImage) { /* ... */ }
```


## Executing Arbitrary SQL

Though we recommend you stick with SQLite.swift’s type-safe system whenever possible, it is possible to simply and safely prepare and execute raw SQL statements via a `Database` connection using the following functions.

  - `execute` runs an arbitrary number of SQL statements as a convenience.

    ``` swift
    db.execute(
        "BEGIN TRANSACTION;" +
        "CREATE TABLE users (" +
            "id INTEGER PRIMARY KEY NOT NULL," +
            "email TEXT UNIQUE NOT NULL," +
            "name TEXT" +
        ");" +
        "CREATE TABLE posts (" +
            "id INTEGER PRIMARY KEY NOT NULL," +
            "title TEXT NOT NULL," +
            "body TEXT NOT NULL," +
            "published_at DATETIME" +
        ");" +
        "PRAGMA user_version = 1;" +
        "COMMIT TRANSACTION;"
    )
    ```

  - `prepare` prepares a single `Statement` object from a SQL string, optionally binds values to it (using the statement’s `bind` function), and returns the statement for deferred execution.

    ``` swift
    let stmt = db.prepare("INSERT INTO users (email) VALUES (?)")
    ```

    Once prepared, statements may be executed using `run`, binding any unbound parameters.

    ``` swift
    stmt.run("alice@mac.com")
    db.lastChanges // -> {Some 1}
    ```

    Statements with results may be iterated over.

    ``` swift
    let stmt = db.prepare("SELECT id, email FROM users")
    for row in stmt {
        println("id: \(row[0]), email: \(row[1])")
        // id: Optional(1), email: Optional("alice@mac.com")
    }
    ```

  - `run` prepares a single `Statement` object from a SQL string, optionally binds values to it (using the statement’s `bind` function), executes, and returns the statement.

    ``` swift
    db.run("INSERT INTO users (email) VALUES (?)", "alice@mac.com")
    ```

  - `scalar` prepares a single `Statement` object from a SQL string, optionally binds values to it (using the statement’s `bind` function), executes, and returns the first value of the first row.

    ``` swift
    db.scalar("SELECT count(*) FROM users") as Int
    ```

    Statements also have a `scalar` function, which can optionally re-bind values at execution.

    ``` swift
    let stmt = db.prepare("SELECT count (*) FROM users")
    stmt.scalar() as Int
    ```


## Logging

We can log SQL using the database’s `trace` function.

``` swift
#if DEBUG
    db.trace(println)
#endif
```


[ROWID]: https://sqlite.org/lang_createtable.html#rowid
