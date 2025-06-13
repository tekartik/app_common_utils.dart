import 'package:tekartik_app_common_utils/yaml_utils.dart';
import 'package:test/test.dart';

void main() {
  group('yaml', () {
    test('decodeYamlMap', () {
      expect(decodeYamlMapOrNull(null), isNull);
      expect(decodeYamlMapOrNull('- test'), isNull);
      expect(decodeYamlMap('test:'), {'test': null});
      expect(decodeYamlMap('test: 1'), {'test': 1});
      expect(decodeYamlMap('test: "1"'), {'test': '1'});
      expect(decodeYamlMap("test: '1'"), {'test': '1'});
      expect(decodeYamlMap('test:'), decodeYamlMapOrNull('test:'));
    });
  });
}
