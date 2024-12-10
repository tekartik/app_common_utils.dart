import 'package:encrypt/encrypt.dart';
import 'package:tekartik_app_crypto/encrypt.dart';
import 'package:tekartik_app_crypto/src/aes.dart';
import 'package:tekartik_app_crypto/src/generate_password.dart'
    show generatePassword;
import 'package:test/test.dart';

void main() {
  void aesRoundTrip(String decoded, String password) {
    var encrypter = aesEncrypterFromPassword(password);
    var encrypted = encrypter.encrypt(decoded);
    // print('${decoded.length}:${encrypted.length}');
    encrypter = aesEncrypterFromPassword(password);
    expect(encrypter.decrypt(encrypted), decoded);
  }

  test('aes encrypt different output', () {
    var password = 'EA5eg5hQVuyPz3EaKqx4vcCJyQZKI5x7';
    var encryptSet = <String>{};
    for (var i = 0; i < 1000; i++) {
      var encrypted = aesEncrypt('test', password);
      print('"test" aesEncrypt by $password: $encrypted');
      encryptSet.add(encrypted);
      if (encryptSet.length > 1) {
        break;
      }
    }
  });
  test('raw aes encrypt decrypt', () {
    var password = r'E4x*$TwbkJC-xK4KGC4zJF9j*Rh&WLgR';
    var encrypter = AesWithIVEntrypter(password, IV.allZerosOfLength(16));

    expect(encrypt('test', password), 'amGhyRRLUIoE59IiEys5Vw==');
    expect(encrypter.encrypt('test'),
        'AAAAAAAAAAAAAAAAAAAAAA==amGhyRRLUIoE59IiEys5Vw==');
    expect(
        encrypter.decrypt('AAAAAAAAAAAAAAAAAAAAAA==amGhyRRLUIoE59IiEys5Vw=='),
        'test');
  });

  test('aes decrypt', () {
    var password = r'E4x*$TwbkJC-xK4KGC4zJF9j*Rh&WLgR';
    var encrypter = aesEncrypterFromPassword(password);

    expect(
        encrypter.encrypt('test'),
        isNot(
            'kEH3mkatSK4yiDu95hZj3Q==0aN1ouMw1HhKY6L8sibkgA==')); // - different each time
    expect(
        encrypter.decrypt('kEH3mkatSK4yiDu95hZj3Q==0aN1ouMw1HhKY6L8sibkgA=='),
        'test');
    expect(
        aesDecrypt(
            'kEH3mkatSK4yiDu95hZj3Q==0aN1ouMw1HhKY6L8sibkgA==', password),
        'test');
    expect(aesEncrypt('test', password),
        isNot('19/EiVx5ICKR/IpS05DYmA==rqLU4PjkNP8W/SiI1dVgAA=='));
    expect(
        aesDecrypt(
            '19/EiVx5ICKR/IpS05DYmA==rqLU4PjkNP8W/SiI1dVgAA==', password),
        'test');
    expect(aesDecrypt(aesEncrypt('test', password), password), 'test');
  });
  test('aes', () {
    var aes = aesEncrypterFromPassword(encryptTextPassword16FromText('test'));
    var encrypted = aes.encrypt('test');
    aes = aesEncrypterFromPassword(encryptTextPassword16FromText('test'));
    expect(aes.decrypt(encrypted), 'test');

    String textWithLength(int length) {
      return List.generate(length, (i) => i.toString().substring(0, 1)).join();
    }

    aesRoundTrip('test', encryptTextPassword16FromText('test'));
    //aesRoundTrip('', '');
    aesRoundTrip('1', encryptTextPassword16FromText('2'));
    aesRoundTrip(textWithLength(4096),
        encryptTextPassword16FromText(textWithLength(4096)));
    // _salsa20RoundTrip(textWithLength(40960), textWithLength(40960));
    aesRoundTrip(textWithLength(4096000),
        encryptTextPassword16FromText(textWithLength(4096000)));

    var password = generatePassword();
    aes = aesEncrypterFromPassword(password);
    var sw = Stopwatch()..start();
    var count = 100;
    for (var i = 0; i < count; i++) {
      aes.decrypt(aes.encrypt(textWithLength(count * 10)));
    }
    // print('aes round trip: ${sw.elapsedMilliseconds} ms');
    sw = Stopwatch()..start();

    for (var i = 0; i < count; i++) {
      aesDecrypt(aesEncrypt(textWithLength(count * 10), password), password);
    }
    print('aesDecrypt/aesEncrypt: ${sw.elapsedMilliseconds} ms');

    var encrypteds = List.generate(count, (index) => '');
    sw = Stopwatch()..start();
    for (var i = 0; i < count; i++) {
      encrypteds[i] = aes.encrypt(textWithLength(count * 10));
    }
    print('aes encrypt: ${sw.elapsedMilliseconds} ms');
    sw = Stopwatch()..start();
    for (var i = 0; i < count; i++) {
      aes.decrypt(encrypteds[i]);
    }
    print('aes decrypt: ${sw.elapsedMilliseconds} ms');
  });
}
