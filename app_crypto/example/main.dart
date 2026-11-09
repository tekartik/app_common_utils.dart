// ignore_for_file: avoid_print

import 'dart:convert';

import 'package:tekartik_app_crypto/encrypt.dart';
import 'package:tekartik_app_crypto/encrypt_codec.dart';
import 'package:tekartik_app_crypto/hash.dart';
import 'package:tekartik_app_crypto/password_generator.dart';

void main() {
  // A 32 characters key (AES-256), to store in a secret place, not in the
  // code.
  var password = generatePassword();

  // Random IV prepended to the output: two calls give different texts.
  var encrypted = aesEncrypt('my local secret', password);
  print(encrypted != aesEncrypt('my local secret', password)); // true
  print(aesDecrypt(encrypted, password)); // my local secret

  // The same as a reusable encrypter and as a dart:convert codec.
  var encrypter = aesEncrypterFromPassword(password);
  var codec = EncryptCodec(encrypter: encrypter);
  var stored = codec.encode(jsonEncode({'token': 'abc'}));
  print(jsonDecode(codec.decode(stored))); // {token: abc}

  // A key from any text (one unsalted MD5: as strong as the text only).
  var derived = encryptTextPassword16FromText('a long pass phrase');
  print(aesDecrypt(aesEncrypt('x', derived), derived)); // x

  // Not for security: a stable id from a text.
  print(md5Hash('https://example.com/a')); // 32 hex characters
}
