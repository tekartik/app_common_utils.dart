import 'package:tekartik_app_crypto/password_generator.dart';
import 'package:test/test.dart';

void main() {
  test('generatePassword', () {
    expect(generatePassword().length, 32);
    expect(generatePassword(length: 10).length, 10);

    expect(generatePassword(length: 64).length, 64);
  });
}
