import 'package:tekartik_app_intl/src/text_locale.dart';
import 'package:test/test.dart';

void main() {
  group('TextLocale', () {
    test('equals', () {
      expect(TextLocale('dummy'), TextLocale('dummy'));
      expect(TextLocale('dummy'), isNot(TextLocale('dummy2')));
    });
  });
}
