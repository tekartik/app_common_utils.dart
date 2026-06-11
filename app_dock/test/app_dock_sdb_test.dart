import 'package:tekartik_app_dock/sdb.dart';
import 'package:test/test.dart';

var testPackageName = 'com.tekartik.app_dock_test';

var testStore = SdbStoreRef<int, SdbModel>('test');

void main() {
  group('sdb', () {
    test('database', () async {
      var factory = dockGetSdbFactory(packageName: testPackageName);
      var dbName = 'test_sdb.db';
      await factory.deleteDatabase(dbName);
      var db = await factory.openDatabase(
        dbName,
        options: SdbOpenDatabaseOptions(
          version: 1,
          onVersionChange: (event) {
            if (event.oldVersion < 1) {
              event.db.createStore(testStore);
            }
          },
        ),
      );
      var key = await testStore.add(db, {'value': 1});
      var snapshot = await testStore.record(key).get(db);
      expect(snapshot!.value, {'value': 1});
      await db.close();
    });
  });
}
