// ignore_for_file: avoid_print

import 'package:path/path.dart';
import 'package:tekartik_app_sqflite/sqflite.dart';

/// Opens (and creates on the first run) the notes database of [factory].
Future<Database> openNotesDatabase(DatabaseFactory factory) {
  return factory.openDatabase(
    'notes.db',
    options: OpenDatabaseOptions(
      version: 2,
      onCreate: (db, version) async {
        await db.execute(
          'CREATE TABLE Note (id INTEGER PRIMARY KEY, title TEXT, done INTEGER)',
        );
      },
      onUpgrade: (db, oldVersion, newVersion) async {
        if (oldVersion < 2) {
          await db.execute('ALTER TABLE Note ADD COLUMN done INTEGER');
        }
      },
    ),
  );
}

/// Run with `dart run example/main.dart` (Dart VM, Linux/Windows/macOS).
Future<void> main() async {
  // A real desktop app passes its packageName: the databases then go to
  // <userAppDataPath>/<packageName>/databases. The example keeps them in the
  // project, in an absolute folder.
  var factory = getDatabaseFactory(
    rootPath: absolute(join('.dart_tool', 'tekartik_app_sqflite_example')),
  );
  print('databases path: ${await factory.getDatabasesPath()}');

  var db = await openNotesDatabase(factory);
  try {
    await db.transaction((txn) async {
      // Use txn, never db, inside a transaction.
      await txn.insert('Note', <String, Object?>{
        'title': 'buy milk',
        'done': 0,
      });
    });
    var count = (await db.query('Note')).length;
    print('$count note(s) in ${db.path}'); // one more on each run
  } finally {
    await db.close();
  }
}
