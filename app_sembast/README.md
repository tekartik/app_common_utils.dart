# tekartik_app_sembast

One sembast `DatabaseFactory` for an app on every platform:
[sembast_sqflite](https://pub.dev/packages/sembast_sqflite) on the Dart VM,
desktop and mobile (over
[tekartik_app_sqflite](../app_sqflite/README.md)), and
[sembast_web](https://pub.dev/packages/sembast_web) (IndexedDB) on the web.
It re-exports the sembast API, and ships a unique secondary index helper
(`unique_index.dart`).

New local database code: use sdb (`package:idb_shim/sdb.dart`, an IndexedDB
like API) instead, with `dockGetSdbFactory` of
[tekartik_app_dock](../app_dock/README.md) in a pure Dart app or
`getSdbFactory` of `tekartik_app_flutter_idb`
([app_flutter_utils](https://github.com/tekartik/app_flutter_utils.dart)) in
a Flutter app. This package is for the apps already on sembast.

## Getting started

Not on pub.dev, add it as a git dependency (Dart SDK `^3.12.0`):

```yaml
dependencies:
  tekartik_app_sembast:
    git:
      url: https://github.com/tekartik/app_common_utils.dart
      path: app_sembast
```

```dart
import 'package:tekartik_app_sembast/sembast.dart';

/// Created once, kept for the whole app.
final databaseFactory = getDatabaseFactory(packageName: 'com.example.my_app');

final settingStore = StoreRef<String, String>.main();

Future<void> main() async {
  // Open once, keep it open.
  var db = await databaseFactory.openDatabase('my_app.db');
  await settingStore.record('theme').put(db, 'dark');
  print(await settingStore.record('theme').get(db)); // dark
  await db.close();
}
```

See [example/main.dart](example/main.dart) and, for the unique index,
[example/unique_index_example.dart](example/unique_index_example.dart) and
[doc/unique_index.md](doc/unique_index.md).

## Platforms

| Platform | Factory | Location of `openDatabase('x.db')` |
|---|---|---|
| Linux, Windows, macOS (Dart VM, Flutter desktop) with `packageName` | sembast_sqflite over sqflite_common_ffi (over the `sqflite` plugin in a Flutter app that has it) | `<userAppDataPath>/<packageName>/databases/x.db` (`~/.config` or `%APPDATA%`) |
| same with `rootPath` (absolute) | same | `<rootPath>/x.db` |
| same without argument | same | `.dart_tool/sqflite_common_ffi/databases/x.db`, relative to the current directory |
| Flutter Android, iOS with the `sqflite` plugin | sembast_sqflite over the plugin | the plugin databases folder |
| Web (dart2js, dart2wasm) | `databaseFactoryWeb`, arguments ignored | IndexedDB database `x.db` |
| Tests | `databaseFactoryMemory` | memory |

SQLite is bundled by the `sqlite3` build hooks on the Dart VM: nothing to
install.

## What to use

* `package:tekartik_app_sembast/sembast.dart`: `getDatabaseFactory({packageName,
  rootPath, autoInit})`, `databaseFactoryMemory` (shared, memory file system)
  and the sembast API (`StoreRef`, `Database`, `Finder`...).
* `package:tekartik_app_sembast/setup/sembast_sqflite_ffi.dart`:
  `databaseFactorySqfliteFfi`, for a VM only program (no web).
* `package:tekartik_app_sembast/unique_index.dart`: a lookup by a unique
  field (`store.index<String>('code')`, `db.index(...)`), kept in memory.

## Common pitfalls

* Call `getDatabaseFactory` once and open each database once: two calls give
  two factories, the same file opened through both is two `Database` objects
  and one reads stale data until it writes.
* Give an absolute `rootPath`: a relative one ends up under
  `.dart_tool/sqflite_common_ffi/databases/<rootPath>`.
* `databaseFactorySqfliteFfi` resolves a relative name in
  `.dart_tool/sqflite_common_ffi/databases`.
* The unique index map is in memory: a transaction that fails after writing
  indexed records leaves it out of sync (dispose it and create it again).

## Agent skills

[skills/tekartik-app-sembast-factory](skills/tekartik-app-sembast-factory/SKILL.md),
[skills/tekartik-app-sembast-unique-index](skills/tekartik-app-sembast-unique-index/SKILL.md).
