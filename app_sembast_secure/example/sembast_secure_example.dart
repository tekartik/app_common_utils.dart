// ignore_for_file: avoid_print

import 'dart:io';

import 'package:path/path.dart';
import 'package:tekartik_app_sembast/sembast.dart';
import 'package:tekartik_app_sembast_secure/sembast_secure.dart';

/// Writes then reads an encrypted database in `.dart_tool/example`, and
/// shows that a wrong password is refused.
Future<void> main() async {
  var path = normalize(
    absolute(join('.dart_tool', 'example', 'example_secure.db')),
  );
  await Directory(dirname(path)).create(recursive: true);

  var factory = EncryptedDatabaseFactory(
    databaseFactory: getDatabaseFactory(),
    password: '1234',
  );
  var store = intMapStoreFactory.store();
  var db = await factory.openDatabase(path);
  var key = await store.add(db, {'test': 1});
  print('record $key: ${await store.record(key).get(db)}');
  await db.close();

  var wrongFactory = EncryptedDatabaseFactory(
    databaseFactory: getDatabaseFactory(),
    password: 'wrong',
  );
  try {
    await wrongFactory.openDatabase(path);
  } on DatabaseException catch (e) {
    // errInvalidCodec
    print('wrong password: ${e.code == DatabaseException.errInvalidCodec}');
  }
}
