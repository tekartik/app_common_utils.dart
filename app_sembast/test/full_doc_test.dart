import 'package:tekartik_app_sembast/sembast.dart';
import 'package:test/test.dart';

void main() {
  test('open/close', () async {
    /// Using in memory implementation for unit test
    var factory = databaseFactoryMemory;
    var db = await factory.openDatabase('test.db');
    // ...
    await db.close();
  });
}
