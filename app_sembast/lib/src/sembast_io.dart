import 'package:sembast_sqflite/sembast_sqflite.dart';
import 'package:tekartik_app_sembast/sembast.dart';
import 'package:tekartik_app_sqflite/sqflite.dart' as sqflite;

/// Use app data on linux and windows if rootPath is null
///
/// Throw if no path defined
DatabaseFactory getDatabaseFactory(
        {String? packageName, String? rootPath, bool autoInit = true}) =>
    getDatabaseFactorySqflite(sqflite.getDatabaseFactory(
        packageName: packageName, rootPath: rootPath, autoInit: autoInit));
