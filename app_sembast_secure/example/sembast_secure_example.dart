import 'dart:io';

import 'package:path/path.dart';
import 'package:tekartik_app_sembast/sembast.dart';
import 'package:tekartik_app_sembast_secure/sembast_secure.dart';

Future<void> main() async {
  var factory = EncryptedDatabaseFactory(
      databaseFactory: getDatabaseFactory(), password: '1234');
  var path =
      normalize(absolute(join('.dart_tool', 'example', 'example_secure.db')));
  await Directory(dirname(path)).create(recursive: true);
  var db = await factory.openDatabase(path);
  await intMapStoreFactory.store().add(db, {'test': 1});
}
