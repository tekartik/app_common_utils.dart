import 'dart:async';
import 'dart:convert';

import 'package:sembast/sembast.dart';
import 'package:sembast/src/file_system.dart';
import 'package:sembast/src/memory/file_system_memory.dart';
import 'package:sembast/src/sembast_fs.dart';
import 'package:tekartik_app_sembast_secure/src/encrypt_codec.dart';
import 'package:test/test.dart';

///
/// helper to read a list of string (lines)
///
Future<List<String>> readContent(FileSystem fs, String filePath) {
  final content = <String>[];
  return utf8.decoder
      .bind(fs.file(filePath).openRead())
      .transform(const LineSplitter())
      .listen((String line) {
    content.add(line);
  }).asFuture(content);
}

void main() {
  late DatabaseFactory factory;
  late FileSystem fs;
  setUp(() {
    fs = FileSystemMemory();
    factory = DatabaseFactoryFs(fs);
  });

  test('EncryptedDatabaseFactory', () async {
    var dbPath = 'test';
    var encryptedFactory = EncryptedDatabaseFactory(
        databaseFactory: factory, password: 'user_password');
    var db = await encryptedFactory.openDatabase(dbPath);
    var store = StoreRef<int, String>.main();
    await store.add(db, 'test');
    await db.close();
    final lines = await readContent(fs, dbPath);
    // print(lines);
    expect(lines.length, 2);
    var codec = encryptedFactory.codec.codec!;
    expect(codec.decode((json.decode(lines.first) as Map)['codec'] as String),
        {'signature': 'encrypt'});
    expect(codec.decode(lines[1]), {'key': 1, 'value': 'test'});
  });
}
