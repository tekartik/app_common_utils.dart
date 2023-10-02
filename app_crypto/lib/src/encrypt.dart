import 'dart:typed_data';

import 'package:encrypt/encrypt.dart';

/// encrypt the [decoded] text using [password].
///
/// [password] must be ascii character of length 16, 24 or 32.
///
/// returns a bast 64 encrypted string.
///
/// Encryption used is AES.
String _encrypt(String decoded, String password) {
  final key = Key.fromUtf8(password);
  final iv = IV(Uint8List(16));
  final encrypter = Encrypter(AES(key));
  return encrypter.encrypt(decoded, iv: iv).base64;
}

/// decrypt the [encoded] text using [password].
///
/// [encoded] is base 64 string got from the encrypt method using the same
/// [password]
///
/// Encryption used is AES.
String _decrypt(String encoded, String password) {
  final key = Key.fromUtf8(password);
  final iv = IV(Uint8List(16));
  final encrypter = Encrypter(AES(key));
  return encrypter.decrypt(Encrypted.fromBase64(encoded), iv: iv);
}

/// encrypt the [decoded] text using [password].
///
/// [password] must be ascii character of length 16, 24 or 32.
///
/// returns a base 64 encrypted string.
///
/// Encryption used is AES.
String encrypt(String decoded, String password) => _encrypt(decoded, password);

/// decrypt the [encoded] text using [password].
///
/// [encoded] is base 64 string got from the encrypt method using the same
/// [password]
///
/// Encryption used is AES.
String decrypt(String encoded, String password) => _decrypt(encoded, password);

/// Encrypt, decrypt helper
abstract class StringEncrypter {
  String encrypt(String input);

  String decrypt(String encrypted);
}

/// Using AES,
/// [password] must be ascii character of length 16, 24 or 32.
class _DefaultEncrypter implements StringEncrypter {
  final String password;

  _DefaultEncrypter(this.password);

  @override
  String decrypt(String encrypted) => _decrypt(encrypted, password);

  @override
  String encrypt(String input) => _encrypt(input, password);
}

/// Using AES,
/// [password] must be ascii character of length 16, 24 or 32.
StringEncrypter defaultEncryptedFromRawPassword(String password) =>
    _DefaultEncrypter(password);
