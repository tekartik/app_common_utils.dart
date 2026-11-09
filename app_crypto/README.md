# tekartik_app_crypto

String in, string out encryption helpers (AES, Salsa20) over
`tekartik_encrypt` (a fork of [encrypt](https://pub.dev/packages/encrypt)),
an MD5 helper and a readable password generator.

## Security first

These helpers obfuscate local or app data. They are not authenticated
encryption, do not use them to protect data an attacker can read or modify
(api requests, tokens sent to a server, cookies):

* No helper has a MAC: AES runs in CTR mode (`AES(key)` defaults to SIC),
  so whoever holds a ciphertext can flip its bits and make it decrypt to a
  chosen text, without the password (`aesEncrypt`, `aesEncrypterFromPassword`,
  Salsa20 too).
* `encrypt`, `decrypt`, `defaultEncryptedFromRawPassword` and
  `defaultEncryptCodec` use a fixed all-zero IV: every value encrypted with
  one password uses the same key stream. Knowing one value and its
  ciphertext reveals the start of all the others. Kept to read old data,
  prefer `aesEncrypt` otherwise.
* `encryptTextPassword16FromText` and the Salsa20 key are one unsalted MD5
  of the text: as strong as the text only.

When integrity matters, use an authenticated mode such as AES-GCM
(`AES(key, mode: AESMode.gcm)` of package:encrypt, a new random 12 byte IV
for each value, stored next to it): a modified value then fails to decrypt.

## Getting started

Not on pub.dev, add it as a git dependency (Dart SDK `^3.12.0`):

```yaml
dependencies:
  tekartik_app_crypto:
    git:
      url: https://github.com/tekartik/app_common_utils.dart
      path: app_crypto
```

```dart
import 'package:tekartik_app_crypto/encrypt.dart';
import 'package:tekartik_app_crypto/password_generator.dart';

void main() {
  // 16, 24 or 32 characters (the key bytes), keep it out of the code.
  var password = generatePassword(length: 32);
  var encrypted = aesEncrypt('my local secret', password); // random IV
  print(aesDecrypt(encrypted, password)); // my local secret
}
```

Pure Dart: Dart VM, Flutter (mobile, desktop, web), browser (dart2js and
dart2wasm); node needs a working `Random.secure` (crypto). See
[example/main.dart](example/main.dart).

## What to use

| Import | API | Use it to |
|---|---|---|
| `encrypt.dart` | `aesEncrypt` / `aesDecrypt`, `aesEncrypterFromPassword` | AES with a random IV prepended (24 base64 chars), password of 16, 24 or 32 UTF-8 bytes |
| `encrypt.dart` | `encrypt` / `decrypt`, `defaultEncryptedFromRawPassword` | legacy deterministic AES (zero IV), to read existing data |
| `encrypt.dart` | `salsa20EncrypterFromPassword` | any password length (MD5 key), random 8 byte IV prepended |
| `encrypt.dart` | `encryptTextPassword16FromText` | a 16 characters AES password from any text |
| `encrypt_codec.dart` | `EncryptCodec(encrypter: ...)`, `defaultEncryptCodec`, `salsa20EncryptCodec` | a `Codec<String, String>` |
| `password_generator.dart` | `generatePassword({length = 32})` | a random key or code (`Random.secure`), no `0 1 i l o L O` |
| `hash.dart` | `md5Hash` | a stable hex id of a text (not for passwords) |

## Common pitfalls

* An AES password that is not 16, 24 or 32 UTF-8 bytes throws (an accented
  character counts for 2 bytes).
* `aesEncrypt` output changes at each call: compare the decrypted texts.
* A wrong password or a damaged text throws or gives garbage (no integrity
  check, see above).
* `generatePassword()` at each run: persist the generated password or the
  encrypted data can no longer be read.

## Agent skills

[skills/](skills/): `tekartik-app-crypto-encrypt` (AES, Salsa20, codecs),
`tekartik-app-crypto-hash-password` (md5Hash, generatePassword).
