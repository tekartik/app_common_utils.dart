import 'dart:io';

import 'package:path/path.dart';
import 'package:process_run/shell_run.dart';
import 'package:sqflite_common/sqlite_api.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import 'sqflite_import.dart';

String buildDatabasesPath(String packageName) {
  var dataPath = join(userAppDataPath, packageName, 'databases');
  try {
    var dir = Directory(dataPath);
    if (!dir.existsSync()) {
      dir.createSync(recursive: true);
    }
  } catch (_) {}
  return dataPath;
}

DatabaseFactory get _defaultDatabaseFactory => databaseFactoryFfi;

/// All but Linux/Windows
DatabaseFactory get databaseFactory => _defaultDatabaseFactory;

/// Use sqflite on any platform
DatabaseFactory getDatabaseFactory({String? packageName, String? rootPath}) {
  var databaseFactory = databaseFactoryFfi;
  // Should not return a future...or ignore
  databaseFactory.compatSetDatabasesPath(
      rootPath ?? buildDatabasesPath(packageName ?? '.'));
  return databaseFactory;
}

void sqfliteWindowsFfiInit() => sqfliteFfiInit();
