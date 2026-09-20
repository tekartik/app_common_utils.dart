---
name: tekartik-app-crypto-encrypt
description: >-
  Use when encrypting or decrypting strings (settings, tokens, local storage
  values) with tekartik_app_crypto: encrypt, decrypt, StringEncrypter,
  defaultEncryptedFromRawPassword, aesEncrypterFromPassword, aesEncrypt,
  aesDecrypt, salsa20EncrypterFromPassword, encryptTextPassword16FromText,
  EncryptCodec, defaultEncryptCodec, salsa20EncryptCodec and the
  encrypt.dart / encrypt_codec.dart imports.
---

# String encryption (tekartik_app_crypto)

`tekartik_app_crypto` wraps `package:tekartik_encrypt` (an `encrypt` fork) in
string-in / string-out helpers: AES with a fixed zero IV (deterministic),
AES with a random IV prepended to the output, and Salsa20. Everything works
on the VM, on the web and in Flutter.

## Guidelines

* Dependency (git, not on pub.dev - the package lives in the `app_crypto/`
  directory of the repo):
  ```yaml
  dependencies:
    tekartik_app_crypto:
      git:
        url: https://github.com/tekartik/app_common_utils.dart
        path: app_crypto
  ```
* Imports: `package:tekartik_app_crypto/encrypt.dart` (functions and
  encrypters) and `package:tekartik_app_crypto/encrypt_codec.dart` (the
  `dart:convert` `Codec` wrappers). Nothing else is public.
* Password rule for every AES entry point: the password must be **16, 24 or
  32 UTF-8 bytes** (128/192/256-bit key) - it is used raw as the key
  (`Key.fromUtf8`), never stretched. Non-ASCII characters count for more than
  one byte. A wrong length throws from the underlying library. Derive a valid
  one from arbitrary text with `encryptTextPassword16FromText(text)` (base64
  of the MD5 digest, truncated to 16 chars) or generate one with
  `generatePassword(length: 32)` from `password_generator.dart`.
* Deterministic AES: `encrypt(text, password)` / `decrypt(base64, password)`
  use an all-zero IV, so the same input always gives the same base64 output.
  That makes values comparable and indexable, but it leaks equality of
  plaintexts - only use it when you need stable ciphertext.
  `defaultEncryptedFromRawPassword(password)` returns the same behaviour as a
  reusable `StringEncrypter`.
* Randomized AES (preferred for stored data): `aesEncrypterFromPassword(
  password)` returns a `StringEncrypter` that generates a fresh 16-byte IV per
  call and prepends it as 24 base64 chars to the ciphertext; `decrypt` reads
  it back. `aesEncrypt(text, password)` / `aesDecrypt(encoded, password)` are
  one-shot versions of the same thing. Two calls on the same input give
  different output - never compare ciphertexts, decrypt and compare.
* Salsa20: `salsa20EncrypterFromPassword(password)` accepts **any** password
  length (it is MD5-hashed into the 16-byte key) and prepends a 12 base64
  chars IV (8 random bytes). Convenient when you cannot control the password
  length; AES is the better default for new code.
* `StringEncrypter` is the common interface (`String encrypt(String input)`,
  `String decrypt(String encrypted)`). Depend on it in your own classes so the
  algorithm stays swappable, and build the instance once (creating it per call
  is wasteful).
* Codecs: `defaultEncryptCodec(rawPassword: ...)` and
  `salsa20EncryptCodec(password: ...)` return an `EncryptCodec`, a
  `Codec<String, String>` - `encode`/`decode`, `encoder`/`decoder`, and it
  fuses with other converters (`jsonEncode` output in, base64 string out).
  `EncryptCodec(encrypter: someStringEncrypter)` wraps any `StringEncrypter`,
  including `aesEncrypterFromPassword(...)`.
* Security caveats to respect: the password is the key, so keep it out of the
  repo; ciphertext is not authenticated (no MAC), so a modified payload may
  decrypt to garbage rather than fail; MD5-derived keys
  (`encryptTextPassword16FromText`, Salsa20) are only as strong as the source
  text. This package protects local/app data, it is not a protocol crypto
  library.
* Anti-patterns: passing a user password of arbitrary length to the AES
  helpers; expecting `aesEncrypt` output to be stable; storing the zero-IV
  output of `encrypt()` for large sets of similar values; re-deriving the
  encrypter on every read in a hot loop.

## Examples

### Deterministic encryption of a settings value

```dart
import 'package:tekartik_app_crypto/encrypt.dart';

void main() {
  // Exactly 32 ASCII characters.
  var password = 'E4x0TwbkJC-xK4KGC4zJF9j0Rh5WLgR1';
  var encrypted = encrypt('my secret', password);
  print(encrypted); // stable base64 for a given input/password
  print(decrypt(encrypted, password)); // my secret
}
```

### Randomized AES with a derived password

```dart
import 'package:tekartik_app_crypto/encrypt.dart';

void main() {
  // Any user text becomes a valid 16 chars password.
  var password = encryptTextPassword16FromText('user pass phrase');
  StringEncrypter encrypter = aesEncrypterFromPassword(password);

  var first = encrypter.encrypt('token-1234');
  var second = encrypter.encrypt('token-1234');
  print(first == second); // false: random IV prepended
  print(encrypter.decrypt(first)); // token-1234
  print(aesDecrypt(second, password)); // token-1234
}
```

### Salsa20 with an arbitrary length password

```dart
import 'package:tekartik_app_crypto/encrypt.dart';

void main() {
  var encrypter = salsa20EncrypterFromPassword('short');
  var encrypted = encrypter.encrypt('hello');
  print(encrypter.decrypt(encrypted)); // hello
}
```

### Encrypted JSON through a Codec

```dart
import 'dart:convert';

import 'package:tekartik_app_crypto/encrypt.dart';
import 'package:tekartik_app_crypto/encrypt_codec.dart';

class SecretStore {
  final EncryptCodec codec;

  /// Randomized AES, password must be 16, 24 or 32 bytes.
  SecretStore(String password)
    : codec = EncryptCodec(encrypter: aesEncrypterFromPassword(password));

  String write(Map<String, Object?> value) => codec.encode(jsonEncode(value));

  Map<String, Object?> read(String encoded) =>
      jsonDecode(codec.decode(encoded)) as Map<String, Object?>;
}

void main() {
  var store = SecretStore(encryptTextPassword16FromText('app-key'));
  var encoded = store.write({'token': 'abc', 'refresh': 'def'});
  print(store.read(encoded)['token']); // abc

  // Deterministic variant, straight from a raw password.
  var codec = defaultEncryptCodec(rawPassword: 'E4x0TwbkJC-xK4KGC4zJF9j0Rh5WLgR1');
  print(codec.decode(codec.encode('test'))); // test
}
```
