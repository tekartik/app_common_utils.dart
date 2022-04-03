import 'package:tekartik_app_intl/intl.dart';
import 'package:test/test.dart';

void main() {
  group('intl', () {
    test('app', () {
      expect(intlSafeKey('count'), 'count');
      expect(intlSafeKey('count: {{count}}'), 'count: ');
    });

    test('intlRender', () {
      expect(intlRender('count'), 'count');
      expect(intlRender('count', data: {'count': '2'}), 'count');
      expect(intlRender('count: {{count}}', data: {'count': '2'}), 'count: 2');
    });

    test('intlSafeLocalizationMap', () {
      expect(
          intlSafeLocalizationMap(
              {'count1': 'v1', 'count2{{param}}': 'v2 {{param}}'}),
          {'count1': 'v1', 'count2': 'v2 {{param}}'});
    });

    test('intlText', () {
      expect(intlText({'k1': 'v1'}, 'k1'), 'v1');
      expect(intlText({'k1': 'v1'}, 'k1', defaultLocalizationMap: {'k1': 'v2'}),
          'v1');
      expect(intlText({'k1': 'v1'}, 'k1_'), '[k1_]');
      expect(
          intlText({'k1': 'v1'}, 'k1_', defaultLocalizationMap: {'k1_': 'v1d'}),
          'v1d');
    });
  });
}
