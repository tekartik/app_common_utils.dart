/// A sqflite [DatabaseFactory] for every platform, and the sqflite_common
/// API (`Database`, `OpenDatabaseOptions`, `Transaction`, `Batch`...).
library;

import 'package:sqflite_common/sqlite_api.dart';

import 'src/sqflite.dart' as src;

export 'package:sqflite_common/sqlite_api.dart';

/// Default database factory: `databaseFactoryFfi` on the Dart VM and desktop
/// (or the `sqflite` plugin factory once a Flutter app registered it, on
/// Android, iOS and macOS), `databaseFactoryFfiWeb` on the web.
DatabaseFactory get databaseFactory => src.databaseFactory;

/// The database factory of an app.
///
/// On Linux, Windows and macOS, with a [packageName], relative paths are
/// opened in `<userAppDataPath>/<packageName>/databases` (created on open);
/// with a [rootPath] (absolute, a relative one is resolved again by the ffi
/// factory), in that folder. Otherwise, and on mobile and on the web, it is
/// [databaseFactory].
///
/// [autoInit] calls [sqfliteWindowsFfiInit].
DatabaseFactory getDatabaseFactory({
  String? packageName,
  String? rootPath,
  bool autoInit = true,
}) => src.getDatabaseFactory(
  packageName: packageName,
  rootPath: rootPath,
  autoInit: autoInit,
);

/// Opens SQLite once in the main isolate on Windows, needed before using
/// [databaseFactory] there; no-op on the other io platforms, throws
/// `UnimplementedError` on the web.
void sqfliteWindowsFfiInit() => src.sqfliteWindowsFfiInit();
