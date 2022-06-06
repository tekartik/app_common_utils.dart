import 'package:tekartik_app_crypto/encrypt.dart';
import 'package:tekartik_app_crypto/src/generate_password.dart'
    show generatePassword;
import 'package:test/test.dart';

void main() {
  void roundTrip(String decoded, String password) {
    expect(decrypt(encrypt(decoded, password), password), decoded);
  }

  void salsa20RoundTrip(String decoded, String password) {
    var encrypter = salsa20EncrypterFromPassword(password);
    var encrypted = encrypter.encrypt(decoded);
    print('${decoded.length}:${encrypted.length}');
    encrypter = salsa20EncrypterFromPassword(password);
    expect(encrypter.decrypt(encrypted), decoded);
  }

  test('test', () {
    var password = r'E4x*$TwbkJC-xK4KGC4zJF9j*Rh&WLgR';
    expect(encrypt('test', password), 'amGhyRRLUIoE59IiEys5Vw==');
    expect(decrypt('amGhyRRLUIoE59IiEys5Vw==', password), 'test');

    roundTrip('a', password);
    roundTrip(
        'Lorem ipsum dolor sit amet, consectetur adipiscing elit, sed do eiusmod tempor incididunt ut labore et dolore magna aliqua. Ut enim ad minim veniam, quis nostrud exercitation ullamco laboris nisi ut aliquip ex ea commodo consequat. Duis aute irure dolor in reprehenderit in voluptate velit esse cillum dolore eu fugiat nulla pariatur. Excepteur sint occaecat cupidatat non proident, sunt in culpa qui officia deserunt mollit anim id est laborum.',
        password);

    // Use accent
    password = r'éx*$TwbkJC-xK4KGC4zJF9j*Rh&WLgR';
    roundTrip('é', password);
  });

  test('checkpassword', () {
    var password = r'test';
    try {
      encrypt('test', password);
      fail('should fail');
    } catch (e) {
      expect(e, isNot(const TypeMatcher<TestFailure>()));
    }
    //  Key length must be 128/192/256 bits
    for (var length in [16, 24, 32]) {
      encrypt('test', generatePassword(length: length));
    }
  });

  test('generatePassword', () {
    expect(generatePassword().length, 32);
    expect(generatePassword(length: 64).length, 64);
  });

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
    print('salsa: ${sw.elapsedMilliseconds} ms');
    sw = Stopwatch()..start();

    for (var i = 0; i < count; i++) {
      decrypt(encrypt(textWithLength(count * 10), password), password);
    }
    print('encrypt: ${sw.elapsedMilliseconds} ms');

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
    sw = Stopwatch()..start();
    for (var i = 0; i < count; i++) {
      encrypteds[i] = encrypt(textWithLength(count * 10), password);
    }
    print('encrypt: ${sw.elapsedMilliseconds} ms');
    sw = Stopwatch()..start();
    for (var i = 0; i < count; i++) {
      decrypt(encrypteds[i], password);
    }
    print('decrypt: ${sw.elapsedMilliseconds} ms');
  });
}
