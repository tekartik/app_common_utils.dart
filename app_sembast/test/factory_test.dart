@TestOn('vm')
library;

import 'package:tekartik_app_sembast/sembast.dart';
import 'package:tekartik_app_sqflite/sqflite.dart' show sqfliteWindowsFfiInit;
import 'package:test/test.dart';

Future main() async {
  sqfliteWindowsFfiInit();
  var factory =
      getDatabaseFactory(packageName: 'tekartik_app_sembast_test.tekartik.com');

  group('sembast', () {
    test('factory', () async {
      expect(await factory.openDatabase('factory_test.db'), isNotNull);
    });
  });
}
