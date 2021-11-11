import 'package:sqflite_common/sqlite_api.dart';

import 'src/sqflite.dart' as src;

export 'package:sqflite_common/sqlite_api.dart';

/// Default database factory, uses ffi on Windows and Linux
DatabaseFactory get databaseFactory => src.databaseFactory;

/// Get the database factory for a given package (setting in home path)
///
/// [packageName] or [rootPath] only used on linux and windows for now
///
/// autoInit is sqflite_ffi on windows
DatabaseFactory getDatabaseFactory(
        {String? packageName, String? rootPath, bool autoInit = true}) =>
    src.getDatabaseFactory(
        packageName: packageName, rootPath: rootPath, autoInit: autoInit);

/// Only needed on Windows during development to find the proper dll location
void sqfliteWindowsFfiInit() => src.sqfliteWindowsFfiInit();
