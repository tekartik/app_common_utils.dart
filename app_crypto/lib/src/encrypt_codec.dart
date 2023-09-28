import 'dart:convert';

import 'package:tekartik_app_crypto/encrypt.dart';

class EncryptConverter with Converter<String, String> {
  final StringEncrypter encrypter;

  EncryptConverter({required this.encrypter});
  @override
  String convert(String input) => encrypter.encrypt(input);
}

class DecryptConverter with Converter<String, String> {
  final StringEncrypter encrypter;

  DecryptConverter({required this.encrypter});
  @override
  String convert(String input) => encrypter.decrypt(input);
}

/// Encrypt codec.
class EncryptCodec with Codec<String, String> {
  final StringEncrypter encrypter;

  EncryptCodec({required this.encrypter});

  @override
  Converter<String, String> get decoder =>
      DecryptConverter(encrypter: encrypter);

  @override
  Converter<String, String> get encoder =>
      EncryptConverter(encrypter: encrypter);
}

/// String password - fixed IV with 0
EncryptCodec defaultEncryptCodec({required String rawPassword}) =>
    EncryptCodec(encrypter: defaultEncryptedFromRawPassword(rawPassword));

/// Any password can be used
EncryptCodec salsa20EncryptCodec({required String password}) =>
    EncryptCodec(encrypter: salsa20EncrypterFromPassword(password));
