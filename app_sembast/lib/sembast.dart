/// One sembast `DatabaseFactory` for an app on every platform
/// ([getDatabaseFactory]), plus the sembast API.
///
/// New local database code: use sdb (`package:idb_shim/sdb.dart`) instead.
library;

import 'package:sembast/sembast.dart';
import 'package:sembast/sembast_memory.dart' as sembast_memory;

import 'src/sembast.dart' as src;

export 'package:sembast/sembast.dart';

/// In memory factory (shared, on a memory file system), for tests.
DatabaseFactory get databaseFactoryMemory =>
    sembast_memory.databaseFactoryMemoryFs;

/// The sembast factory of the platform; call it once and keep the factory.
///
/// * Linux, Windows, macOS (Dart VM, Flutter desktop): sembast_sqflite over
///   sqflite_common_ffi (over the `sqflite` plugin in a Flutter app that has
///   it). With [packageName], relative names are opened in
///   `<userAppDataPath>/<packageName>/databases`; with an absolute
///   [rootPath], in that folder (a relative [rootPath] ends up under
///   `.dart_tool/sqflite_common_ffi/databases`); with neither, in
///   `.dart_tool/sqflite_common_ffi/databases`.
/// * Flutter Android and iOS: sembast_sqflite over the `sqflite` plugin
///   (arguments ignored).
/// * Web: `databaseFactoryWeb` (IndexedDB, arguments ignored).
///
/// [autoInit] calls `sqfliteWindowsFfiInit()` (io only).
///
/// Each call returns a new factory: the same database opened through two
/// factories is two `Database` objects (one reads stale data until it
/// writes).
DatabaseFactory getDatabaseFactory({
  String? packageName,
  String? rootPath,
  bool autoInit = true,
}) => src.getDatabaseFactory(
  packageName: packageName,
  rootPath: rootPath,
  autoInit: autoInit,
);
