import 'dart:convert';

import 'package:crypto/crypto.dart';
import 'package:encrypt/encrypt.dart';

import 'encrypt.dart';

/// Simple md5 hash
String encryptTextPassword16FromText(String password) {
  return base64Encode(md5.convert(utf8.encode(password)).bytes)
      .substring(0, 16);
}

/// aes encrypted using any password (use MD5), random data prepended
StringEncrypter aesEncrypterFromPassword(String password) {
  return _AesStringEncrypter(_aesEncrypterFromPassword(password));
}

Encrypter _aesEncrypterFromPassword(String password) {
  final key = Key.fromUtf8(password); // _generateEncryptPassword(password));
  return Encrypter(AES(key));
}

class _AesStringEncrypter implements StringEncrypter {
  final Encrypter encrypter;

  _AesStringEncrypter(this.encrypter);
  @override
  String decrypt(String encrypted) {
    // Read the initial value that was prepended
    assert(encrypted.length >= 24);
    final iv = base64.decode(encrypted.substring(0, 24));

    // Extract the real input
    encrypted = encrypted.substring(24);

    // Decode the input
    var decoded = encrypter.decrypt64(encrypted, iv: IV(iv));
    return decoded;
  }

  IV _generateIv() {
    final iv = IV.fromSecureRandom(16);
    return iv;
  }

  @override
  String encrypt(String input) {
    final iv = _generateIv();

    // Encode the input value
    final encoded = encrypter.encrypt(input, iv: iv).base64;

    var ivEncoded = iv.base64;
    assert(ivEncoded.length == 24);
    // Prepend the initial value
    return '$ivEncoded$encoded';
  }
}

class AesWithIVEntrypter extends _AesStringEncrypter {
  final IV iv;

  /// Must be 16 bytes
  final String password;
  AesWithIVEntrypter(this.password, this.iv)
      : super(_aesEncrypterFromPassword(password));
  @override
  IV _generateIv() {
    return iv;
  }
}

/// encrypt the [decoded] text using [password].
///
/// [password] must be ascii character of length 16, 24 or 32.
///
/// returns a base 64 encrypted string.
///
/// Encryption used is AES. Calling multiple times will not return the same
/// result as a salt is added to the input.
String aesEncrypt(String decoded, String password) =>
    aesEncrypterFromPassword(password).encrypt(decoded);

/// decrypt the [encoded] text using [password].
///
/// [encoded] is base 64 string got from the encrypt method using the same
/// [password]
///
/// Encryption used is AES.
String aesDecrypt(String encoded, String password) =>
    aesEncrypterFromPassword(password).decrypt(encoded);
