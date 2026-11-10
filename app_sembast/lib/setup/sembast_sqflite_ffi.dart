import 'package:sembast_sqflite/sembast_sqflite.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart' as sqflite_ffi;

export 'package:sembast/sembast.dart';

/// Sembast sqflite ffi based database factory, for a Dart VM program (Linux,
/// Windows, macOS; not the web).
///
/// A relative name is opened in the sqflite_common_ffi databases folder
/// (`.dart_tool/sqflite_common_ffi/databases`): pass an absolute path to
/// choose the folder.
final databaseFactorySqfliteFfi = getDatabaseFactorySqflite(
  sqflite_ffi.databaseFactoryFfi,
);
