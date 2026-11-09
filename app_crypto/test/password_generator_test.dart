import 'package:tekartik_app_crypto/password_generator.dart';
import 'package:test/test.dart';

void main() {
  test('generatePassword', () {
    expect(generatePassword().length, 32);
    expect(generatePassword(length: 10).length, 10);

    expect(generatePassword(length: 64).length, 64);
  });
  test('generatePassword characters', () {
    // No 0, 1, i, l, o, L, O.
    expect(
      generatePassword(length: 1000),
      matches(RegExp(r'^[2-9a-hjkmnp-zA-KMNP-Z]+$')),
    );
  });
}
