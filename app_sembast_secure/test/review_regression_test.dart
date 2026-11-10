import 'package:sembast/sembast_memory.dart';
import 'package:sembast/src/memory/file_system_memory.dart';
import 'package:sembast/src/sembast_fs.dart';
import 'package:tekartik_app_sembast_secure/sembast_secure.dart';
import 'package:test/test.dart';

void main() {
  group('EncryptedDatabaseFactory', () {
    test('pathContext is the delegate one', () {
      var delegate = newDatabaseFactoryMemory();
      var factory = EncryptedDatabaseFactory(
        databaseFactory: delegate,
        password: 'user_password',
      );
      expect(factory.pathContext, delegate.pathContext);
    });

    test('sandbox', () async {
      // Memory file system: the codec signature is checked at open.
      var delegate = DatabaseFactoryFs(FileSystemMemory());
      var factory = EncryptedDatabaseFactory(
        databaseFactory: delegate,
        password: 'user_password',
      );
      var sandbox = factory.sandbox(path: 'user1');
      var store = StoreRef<int, String>.main();
      var db = await sandbox.openDatabase('test.db');
      await store.add(db, 'secret');
      await db.close();

      // Encrypted, below the sandbox root.
      expect(await delegate.databaseExists('user1/test.db'), isTrue);
      await expectLater(
        delegate.openDatabase('user1/test.db'),
        throwsA(isA<DatabaseException>()),
      );
      db = await factory.openDatabase('user1/test.db');
      expect(await store.record(1).get(db), 'secret');
      await db.close();
    });
  });
}
