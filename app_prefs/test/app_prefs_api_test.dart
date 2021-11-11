import 'package:tekartik_app_common_prefs/app_prefs.dart';
import 'package:test/test.dart';

void main() async {
  group('getPrefsFactory', () {
    test('def', () {
      // ignore: unnecessary_statements
      Prefs;
      // ignore: unnecessary_statements
      PrefsFactory;
      // ignore: unnecessary_statements
      getPrefsFactory;
      prefsFactory;
      prefsFactoryMemory;
      print(prefsFactory.runtimeType); // ignore: avoid_print
    });
  });
}
