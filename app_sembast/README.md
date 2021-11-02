# tekartik_app_sembast

This package allow a simplified sembast initialization to support multiple platforms (DartVM/io and web).
The abstraction is done at the database factory used within an application.

Sembast database factory for app (mobile & web).

* On Desktop Windows/Linux/MacOS, [sembast_sqflite](https://pub.dev/packages/sembast_sqflite) will be used 
  based on [sqflite_commmon_ffi](https://pub.dev/packages/sqflite_common_ffi)
* On Web, [sembast_web](https://pub.dev/packages/sembast_web) will be used based on
  IndexedDB
* In unit test, `databaseFactoryMemory` should be used from [sembast](https://pub.dev/packages/sembast)

## Getting Started

### Setup

```yaml
dependencies:
  tekartik_app_sembast:
    git:
      url: https://github.com/tekartik/app_common_utils.dart
      ref: dart2_3
      path: app_sembast
    version: '>=0.1.0'
```

### Usage

Simplified usage: 
* Open your database only once in your application 
* Keep it open

```dart
Future main() {
  // Get the sembast database factory according to the current platform
  // * sembast_web for FlutterWeb and Web
  // * sembast_sqflite and sqflite on Flutter iOS/Android/MacOS
  var factory = getDatabaseFactory();
  var store = StoreRef<String, String>.main();
  // Open the database
  var db = await factory.openDatabase('test.db');
  await store.record('key').put(db, 'value');
  
  // Not needed in a flutter application
  await db.close();
}
```

### Usage in unit test

```dart
import 'package:test/test.dart';
import 'package:tekartik_app_sembast/sembast.dart';

void main() {
  test('open/close', () async {
    /// Using in memory implementation for unit test
    var factory = databaseFactoryMemory;
    var db = await factory.openDatabase('test.db');
    // ...
    await db.close();
  });
}
```
