import 'package:sqflite_common/sqlite_api.dart';
import 'package:sqflite_common_ffi_web/sqflite_ffi_web.dart';

DatabaseFactory get databaseFactory => databaseFactoryFfiWeb;

DatabaseFactory getDatabaseFactory({
  String? packageName,
  String? rootPath,
  bool autoInit = true,
}) => databaseFactory;

/// Only needed/implemented on windows
void sqfliteWindowsFfiInit() => _stub('sqfliteWindowsFfiInit');

/// no op on the web
String getDatabasePath(
  String databasePath, {
  String? packageName,
  String? rootPath,
}) => databasePath;

T _stub<T>(String message) {
  throw UnimplementedError(message);
}
