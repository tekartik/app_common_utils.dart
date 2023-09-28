import 'package:tekartik_app_crypto/encrypt.dart';
import 'package:tekartik_app_crypto/src/generate_password.dart'
    show generatePassword;
import 'package:test/test.dart';

void main() {
  void salsa20RoundTrip(String decoded, String password) {
    var encrypter = salsa20EncrypterFromPassword(password);
    var encrypted = encrypter.encrypt(decoded);
    print('${decoded.length}:${encrypted.length}');
    encrypter = salsa20EncrypterFromPassword(password);
    expect(encrypter.decrypt(encrypted), decoded);
  }

  test('salsa20', () {
    var salsa = salsa20EncrypterFromPassword('test');
    var encrypted = salsa.encrypt('test');
    salsa = salsa20EncrypterFromPassword('test');
    expect(salsa.decrypt(encrypted), 'test');

    String textWithLength(int length) {
      return List.generate(length, (i) => i.toString().substring(0, 1)).join();
    }

    salsa20RoundTrip('test', 'test');
    salsa20RoundTrip('', '');
    salsa20RoundTrip('1', '2');
    salsa20RoundTrip(textWithLength(4096), textWithLength(4096));
    // _salsa20RoundTrip(textWithLength(40960), textWithLength(40960));
    salsa20RoundTrip(textWithLength(4096000), textWithLength(4096000));

    var password = generatePassword();
    salsa = salsa20EncrypterFromPassword(password);
    var sw = Stopwatch()..start();
    var count = 1000;
    for (var i = 0; i < count; i++) {
      salsa.decrypt(salsa.encrypt(textWithLength(count * 10)));
    }
    print('salsa round trip: ${sw.elapsedMilliseconds} ms');

    var encrypteds = List.generate(count, (index) => '');
    sw = Stopwatch()..start();
    for (var i = 0; i < count; i++) {
      encrypteds[i] = salsa.encrypt(textWithLength(count * 10));
    }
    print('salsa encrypt: ${sw.elapsedMilliseconds} ms');
    sw = Stopwatch()..start();
    for (var i = 0; i < count; i++) {
      salsa.decrypt(encrypteds[i]);
    }
    print('salsa decrypt: ${sw.elapsedMilliseconds} ms');
  });
}
