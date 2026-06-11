import 'package:tekartik_app_dock/fs.dart';
import 'package:test/test.dart';

var testPackageName = 'com.tekartik.app_dock_test';

void main() {
  group('fs', () {
    test('fs', () async {
      var fs = dockGetAppDataFileSystem(packageName: testPackageName);
      expect(fs, isNotNull);
      var dir = fs.directory(fs.path.join('test', 'fs'));
      await dir.create(recursive: true);
      var file = dir.file('test.txt');
      await file.writeAsString('test');
      expect(await file.readAsString(), 'test');
      await dir.delete(recursive: true);
    });
    test('path helpers', () {
      expect(dockGetAppDataPath(packageName: testPackageName), isNotEmpty);
    });
  });
}
