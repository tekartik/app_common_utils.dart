## Sembast unique index experimentation.

Everything is in one file so can be copy/pasted or you can import this lib as a git dependency. See [README.md](../README.md).
By default sembast has a single primary key index which can be an int or a String.

Here is a solution to add an additional unique index (a custom key is considered unique here but an alternative solution could support non-unique index)

An index definition can be declared globally on a store:

```dart
import 'package:tekartik_app_sembast/sembast.dart';
import 'package:tekartik_app_sembast/unique_index.dart';

/// our book store
var bookStore = intMapStoreFactory.store('book');

/// Our index on the `code` field which is a String
var codeIndex = bookStore.index<String>('code');
```

An active database index can be created once the database is opened. It will allow quick access by index key.

```dart
var db = await databaseFactory.openDatabase('test.db');

// Create our db active index.
dbCodeIndex = db.index(codeIndex);
```

By default, it does not ensure uniqueness. If you want to throw on conflicts you can use:

```dart
dbCodeIndex = db.index(codeIndex, throwOnConflict: true);
```

Let's add some data for demo purpose

```dart
// Add some data
await bookStore.addAll(db, [
  {'code': 'BOOK001', 'title': 'The great book'},
  {'code': 'BOOK002', 'title': 'The simple book'}
]);
```

Access by index can done the following way:

```dart
  /// Access a book by code
var book = (await dbCodeIndex.record('BOOK001').getSnapshot())!;

/// Should print the great book!
print(book['title']);
```

Or in a transaction:

```dart
/// You can also read in a transaction.
await db.transaction((transaction) async {
  /// Access a book by code
  var book = (await dbCodeIndex
    .transactionRecord(transaction, 'BOOK002')
    .getSnapshot())!;

  /// Should print the simple book!
  print(book['title']);
});
```