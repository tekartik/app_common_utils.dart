import 'package:tekartik_app_dock/sembast.dart';
import 'package:tekartik_common_utils/env_utils.dart';
import 'package:test/test.dart';

var testPackageName = 'com.tekartik.app_dock_test';

void main() {
  group('sembast', () {
    test('database', () async {
      var factory = dockGetSembastDatabaseFactory(packageName: testPackageName);
      var dbName = 'test_sembast.db';
      await factory.deleteDatabase(dbName);
      var db = await factory.openDatabase(dbName);
      var store = StoreRef<String, Object>.main();
      await store.record('key').put(db, 'value');
      expect(await store.record('key').get(db), 'value');
      await db.close();
    });
    test('sembast_io', () {
      try {
        databaseFactoryIo;
      } on UnimplementedError catch (_) {
        expect(kDartIsWeb, true);
      }
    });
  });
}
