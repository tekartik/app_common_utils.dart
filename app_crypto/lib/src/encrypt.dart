import 'package:encrypt/encrypt.dart';

/// encrypt the [decoded] text using [password].
///
/// [password] must be ascii character of length 16, 24 or 32.
///
/// returns a bast 64 encrypted string.
///
/// Encryption used is AES.
String encrypt(String decoded, String password) {
  final key = Key.fromUtf8(password);
  final iv = IV.fromLength(16);
  final encrypter = Encrypter(AES(key));
  return encrypter.encrypt(decoded, iv: iv).base64;
}

/// decrypt the [encoded] text using [password].
///
/// [encoded] is base 64 string got from the encrypt method using the same
/// [password]
///
/// Encryption used is AES.
String decrypt(String encoded, String password) {
  final key = Key.fromUtf8(password);
  final iv = IV.fromLength(16);
  final encrypter = Encrypter(AES(key));
  return encrypter.decrypt(Encrypted.fromBase64(encoded), iv: iv);
}
