---
name: tekartik-app-crypto-hash-password
description: >-
  Use when hashing a string to a stable id or generating a random password/key
  with tekartik_app_crypto: md5Hash from hash.dart, generatePassword from
  password_generator.dart, its length parameter and excluded confusing
  characters, and how to feed the result to the AES helpers.
---

# MD5 hash and password generation (tekartik_app_crypto)

Two independent one-function libraries of `tekartik_app_crypto`: `md5Hash`
turns any string into a stable hex digest (ids, cache keys, etag-like
values) and `generatePassword` produces a readable random string usable as an
AES key for the package's encryption helpers.

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
* `import 'package:tekartik_app_crypto/hash.dart';` exposes exactly
  `String md5Hash(String input)`: UTF-8 encodes the input and returns the
  lowercase 32-char hex MD5 digest (`package:crypto`). Stable across
  platforms and runs, so it is a good document id, cache key or
  change-detection fingerprint.
* MD5 is **not** for passwords or signatures: never store `md5Hash(password)`
  as a credential and never use it to authenticate content. For a digest of
  large data, use `package:crypto` directly with a stronger hash.
* `import 'package:tekartik_app_crypto/password_generator.dart';` exposes
  `String generatePassword({int length = 32})`: alphanumeric only, with the
  confusing characters `i l 1 L 0 o O` removed, so the result is safe to read
  aloud or copy from a screen.
* Pick the length to match the consumer: `16`, `24` or `32` for the AES
  helpers of this package (`encrypt`, `aesEncrypterFromPassword`,
  `defaultEncryptCodec`), which need a key of exactly that many UTF-8 bytes.
  The generated characters are all ASCII, so length == byte count.
* It uses `Random()` (not `Random.secure()`), so treat it as a convenience
  generator for local/dev secrets, seeds and test fixtures. For a
  high-value secret, generate it with `Random.secure()` or outside the app,
  and store it in your secret manager - not in the repo.
* Anti-patterns: calling `generatePassword()` at each run and wondering why
  previously encrypted data no longer decrypts (persist the generated
  password); assuming `generatePassword` includes symbols (it does not);
  using `md5Hash` output as an AES password without truncating to a valid
  length (use `encryptTextPassword16FromText` from `encrypt.dart` instead).

## Examples

### Stable id / cache key from a url

```dart
import 'package:tekartik_app_crypto/hash.dart';

String cacheKey(Uri uri) => md5Hash(uri.toString());

void main() {
  var key = cacheKey(Uri.parse('https://example.com/a/b?c=1'));
  print(key); // 32 lowercase hex chars, same on every platform
  print(key == cacheKey(Uri.parse('https://example.com/a/b?c=1'))); // true
}
```

### Generate a key for the AES helpers

```dart
import 'package:tekartik_app_crypto/encrypt.dart';
import 'package:tekartik_app_crypto/password_generator.dart';

void main() {
  // 32 chars = 256 bits key, no confusing characters.
  var password = generatePassword();
  print('store this: $password');

  var encrypted = aesEncrypt('my secret', password);
  print(aesDecrypt(encrypted, password)); // my secret

  // Shorter keys are valid too: 16 or 24.
  var shortKey = generatePassword(length: 16);
  print(encrypt('x', shortKey).isNotEmpty);
}
```

### Readable one-time codes

```dart
import 'package:tekartik_app_crypto/password_generator.dart';

void main() {
  var code = generatePassword(length: 8);
  print('share code: $code'); // e.g. 'Kf7Rhp2W', never contains i l 1 L 0 o O
}
```
