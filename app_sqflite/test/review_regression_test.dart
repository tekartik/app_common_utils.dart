@TestOn('vm')
library;

import 'dart:io';

import 'package:path/path.dart';
import 'package:tekartik_app_sqflite/sqflite.dart';
import 'package:test/test.dart';

void main() {
  sqfliteWindowsFfiInit();
  // Desktop only: packageName/rootPath are ignored elsewhere.
  var isDesktop = Platform.isLinux || Platform.isWindows || Platform.isMacOS;
  // Absolute: a relative rootPath is resolved again by the delegate factory.
  var rootPath = absolute(
    join('.dart_tool', 'tekartik_app_sqflite', 'test', 'review'),
  );

  setUpAll(() async {
    var dir = Directory(rootPath);
    if (dir.existsSync()) {
      await dir.delete(recursive: true);
    }
  });

  group('getDatabaseFactory(rootPath:)', () {
    test(
      'setDatabasesPath',
      () async {
        var factory = getDatabaseFactory(rootPath: rootPath);
        expect(await factory.getDatabasesPath(), rootPath);
        var otherPath = join(rootPath, 'other');
        // Used to throw LateInitializationError (late final set twice).
        await factory.setDatabasesPath(otherPath);
        expect(await factory.getDatabasesPath(), otherPath);
        var db = await factory.openDatabase('set_path.db');
        await db.close();
        expect(File(join(otherPath, 'set_path.db')).existsSync(), isTrue);
      },
      skip: isDesktop ? false : 'desktop only',
      timeout: const Timeout(Duration(seconds: 30)),
    );

    test(
      'in memory database',
      () async {
        var memoryRootPath = join(rootPath, 'memory');
        var factory = getDatabaseFactory(rootPath: memoryRootPath);
        for (var path in [inMemoryDatabasePath, 'file::memory:']) {
          Future<int> openInsertCount() async {
            var db = await factory.openDatabase(
              path,
              options: OpenDatabaseOptions(
                version: 1,
                onCreate: (db, version) async {
                  await db.execute(
                    'CREATE TABLE Test (id INTEGER PRIMARY KEY)',
                  );
                },
              ),
            );
            try {
              await db.insert('Test', <String, Object?>{'id': null});
              return (await db.query('Test')).length;
            } finally {
              await db.close();
            }
          }

          // A new in memory database each time, nothing on disk.
          expect(await openInsertCount(), 1, reason: path);
          expect(await openInsertCount(), 1, reason: path);
          expect(File(join(memoryRootPath, path)).existsSync(), isFalse);
        }
      },
      skip: isDesktop ? false : 'desktop only',
      timeout: const Timeout(Duration(seconds: 30)),
    );
  });
}
