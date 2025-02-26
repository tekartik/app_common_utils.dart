import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';

import 'package:crypto/crypto.dart';
import 'package:tekartik_encrypt/encrypt.dart';

import 'encrypt.dart';

/// Generate an encryption password based on a user input password
///
/// It uses MD5 which generates a 16 bytes blob, size needed for Salsa20
Uint8List _generateEncryptPassword(String password) {
  var blob = Uint8List.fromList(md5.convert(utf8.encode(password)).bytes);
  assert(blob.length == 16);
  return blob;
}

/// Salsa 20 encrypted using any password (use MD5), random data prepended
StringEncrypter salsa20EncrypterFromPassword(String password) {
  final key = Key(_generateEncryptPassword(password));
  return _Salsa20StringEncrypter(Encrypter(Salsa20(key)));
}

var _random = Random.secure();

/// Random bytes generator
Uint8List _randBytes(int length) {
  return Uint8List.fromList(
      List<int>.generate(length, (i) => _random.nextInt(256)));
}

class _Salsa20StringEncrypter implements StringEncrypter {
  final Encrypter encrypter;

  _Salsa20StringEncrypter(this.encrypter);
  @override
  String decrypt(String encrypted) {
    // Read the initial value that was prepended
    assert(encrypted.length >= 12);
    final iv = base64.decode(encrypted.substring(0, 12));

    // Extract the real input
    encrypted = encrypted.substring(12);

    // Decode the input
    var decoded = encrypter.decrypt64(encrypted, iv: IV(iv));
    return decoded;
  }

  @override
  String encrypt(String input) {
    final iv = _randBytes(8);
    final ivEncoded = base64.encode(iv);
    assert(ivEncoded.length == 12);

    // Encode the input value
    final encoded = encrypter.encrypt(input, iv: IV(iv)).base64;

    // Prepend the initial value
    return '$ivEncoded$encoded';
  }
}
