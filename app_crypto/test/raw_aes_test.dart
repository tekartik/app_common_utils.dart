import 'dart:typed_data';

import 'package:encrypt/encrypt.dart';
import 'package:test/test.dart';

/// Old bidirectional encryption
String legacyAesEncrypt(String decoded, String password) {
  final key = Key.fromUtf8(password);
  // final iv = IV.fromLength(16);
  final iv = IV(Uint8List(16));
  final encrypter = Encrypter(AES(key));
  return encrypter.encrypt(decoded, iv: iv).base64;
}

/// Old bidirectional encryption
String legacyAesDecrypt(String encoded, String password) {
  final key = Key.fromUtf8(password);
  // final iv = IV.fromLength(16);
  final iv = IV(Uint8List(16));
  final encrypter = Encrypter(AES(key));
  return encrypter.decrypt(Encrypted.fromBase64(encoded), iv: iv);
}

void main() {
  test('AES encrypt/decrypt', () {
    var password = r'E4x*$TwbkJC-xK4KGC4zJF9j*Rh&WLgR';
    expect(legacyAesEncrypt('test', password), 'amGhyRRLUIoE59IiEys5Vw==');
    expect(legacyAesDecrypt('amGhyRRLUIoE59IiEys5Vw==', password), 'test');
  });
}
