# tekartik_app_sqflite

sqflite database factory for app (desktop VM/io & web)
- Uses sqflite_common_ffi on Linux/Windows/Mac and mobile
- No web support

## Getting Started

### Setup

```yaml
dependencies:
  tekartik_app_sqflite:
    git:
      url: https://github.com/tekartik/app_common_utils.dart
      ref: dart2_3
      path: app_sqflite
    version: '>=0.2.0'
```

### Usage

```dart
import 'package:tekartik_app_sqflite/sqflite.dart';

Future<Database> open() async {
  var db = await databaseFactory.openDatabase('test.db',
      options: OpenDatabaseOptions(
          version: 1,
          onCreate: (db, version) async {
            await db.execute('''
    CREATE TABLE Pref (
      id TEXT PRIMARY KEY,
      value INTEGER NOT NULL
    )
            ''');
          }));
  await db.close();
}
```

Since `getDatabasePath()` implementation is lame on platform other than Android, you should use a package such as 
`path_provider` to find the proper database location.