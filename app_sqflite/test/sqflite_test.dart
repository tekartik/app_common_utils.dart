import 'package:tekartik_app_sqflite/sqflite.dart';
import 'package:test/test.dart';

void main() {
  sqfliteWindowsFfiInit();
  DatabaseFactory factory;
  setUpAll(() async {});

  test('databases path', () async {
    factory = databaseFactory;
    var dummyDatabasesPath = await factory.getDatabasesPath();
    expect(dummyDatabasesPath, isNotNull);
  });

  test('doc', () async {
    var db = await databaseFactory.openDatabase(
      'test.db',
      options: OpenDatabaseOptions(
        version: 1,
        onCreate: (db, version) async {
          await db.execute('''
    CREATE TABLE Pref (
      id TEXT PRIMARY KEY,
      value INTEGER NOT NULL
    )
              ''');
        },
      ),
    );
    await db.close();
  });

  test('init', () async {
    // ignore: deprecated_member_use_from_same_package
    factory = getDatabaseFactory(packageName: 'com.tekartik.dummy.app');
    var dummyDatabasesPath = await factory.getDatabasesPath();
    expect(dummyDatabasesPath, isNotNull);
    expect(dummyDatabasesPath, contains('dummy.app'));
    // print(dummyDatabasesPath);
    // ignore: deprecated_member_use_from_same_package
    factory = getDatabaseFactory();
    expect(await factory.getDatabasesPath(), isNotNull);
    expect(await factory.getDatabasesPath(), isNot(dummyDatabasesPath));
  });

  test('get', () async {
    factory = getDatabaseFactory(packageName: 'com.tekartik.dummy.app');
    var dummyDatabasesPath = await factory.getDatabasesPath();
    expect(dummyDatabasesPath, isNotNull);
    expect(dummyDatabasesPath, contains('dummy.app'));
    // print(dummyDatabasesPath);
    factory = getDatabaseFactory();
    expect(await factory.getDatabasesPath(), isNotNull);
    expect(await factory.getDatabasesPath(), isNot(dummyDatabasesPath));
  });
}
