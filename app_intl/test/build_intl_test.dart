import 'package:tekartik_app_intl/build_intl.dart';
import 'package:test/test.dart';

void main() {
  group('build_intl', () {
    test('FixAndGenNormal', () async {
      var project = LocalizationProject('test/project');
      await project.intlFixAndGenerate();
    });
    test('FixAndGenNoEnUs', () async {
      var project = LocalizationProject('test/project_no_en_us');
      await project.intlFixAndGenerate(noEnUs: true);
    });
  });
}
