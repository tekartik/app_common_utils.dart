import 'dart:convert';
import 'dart:math';

import 'package:crypto/crypto.dart';

/// The key a release build of an app asks in its url (`?agent=<key>`)
/// before exposing its commands to the page scripts.
///
/// The app holds only the hash of the key ([AgentKey.hashed]): a build never
/// contains the key itself. The key and the links are documented in the
/// generated agent constants of the project (`agentConstantsGenerate` of
/// `package:tekartik_app_agent/agent_constants_io.dart`), in its private
/// repository. The hash is computed only when a url carries `?agent=`
/// ([matches]); [toString] never shows it.
class AgentKey {
  final String _hash;

  /// The key whose hash is [hash] ([hashOf]).
  const AgentKey.hashed(String hash) : _hash = hash;

  /// Whether [key] (the `agent` url parameter) is this key.
  bool matches(String? key) =>
      key != null && key.isNotEmpty && hashOf(key) == _hash;

  /// The hash of [key]: the SHA-256 of `tekartik_app_agent:<key>`, base64url
  /// without padding.
  static String hashOf(String key) => base64Url
      .encode(sha256.convert(utf8.encode('tekartik_app_agent:$key')).bytes)
      .replaceAll('=', '');

  /// A new random key: 24 random bytes ([random], `Random.secure()` by
  /// default), base64url (32 characters, url safe).
  static String generate([Random? random]) {
    random ??= Random.secure();
    return base64Url.encode([for (var i = 0; i < 24; i++) random.nextInt(256)]);
  }

  @override
  String toString() => 'AgentKey(***)';
}
