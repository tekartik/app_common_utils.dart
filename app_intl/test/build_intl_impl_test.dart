import 'package:tekartik_app_intl/src/build_intl.dart';
import 'package:test/test.dart';

void main() {
  group('build_intl_impl', () {
    test('lowerCamelCase', () async {
      expect(fixKeyName(''), '');
      expect(fixKeyName('a'), 'a');
      expect(fixKeyName('a_b'), 'aB');
      expect(fixKeyName('aa_bb_ccDd'), 'aaBbCcDd');
    });
  });
}
