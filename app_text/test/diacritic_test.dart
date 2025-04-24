import 'package:tekartik_app_text/diacritic.dart';
import 'package:tekartik_app_text/sanitize.dart';
import 'package:test/test.dart';

Future<void> main() async {
  test('removeDiacritics', () {
    expect(sanitizeString(' Hello'), 'hello');
    expect(' élève ?\r'.removeDiacritics(), ' eleve ?\r');
  });
}
