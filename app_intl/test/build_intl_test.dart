import 'package:tekartik_app_intl/build_intl.dart';
import 'package:test/test.dart';

void main() {
  group('build_intl', () {
    test('FixAndGen', () async {
      var project = LocalizationProject('test/project');
      await project.intlFixAndGenerate();
    });
  });
}
