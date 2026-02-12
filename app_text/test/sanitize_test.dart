import 'package:tekartik_app_text/sanitize.dart';
import 'package:test/test.dart';

Future<void> main() async {
  test('sanitizeString', () {
    expect(sanitizeString(' Hello'), 'hello');
    expect(sanitizeString(' élè\t\nve ?-\r'), 'ele_ve');
  });
  test('sanitizeText', () {
    var sanitizedText = sanitizeText(' Hello ? world');
    expect(sanitizedText.sanitizedWords, ['hello', 'world']);
  });
}
