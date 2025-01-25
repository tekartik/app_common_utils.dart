import 'dart:convert';
import 'dart:typed_data';

/// Abstracted root bundle
abstract class TkAssetBundle {
  /// Load a string
  Future<String> loadString(String key);

  /// Load bytes
  Future<ByteData> loadByteData(String key);

  /// Load bytes
  Future<Uint8List> loadBytes(String key);
}

/// Memory implementation of [TkAssetBundle]
class TkAssetBundleMemory implements TkAssetBundle {
  final Map<String, Uint8List> _bytesMap = {};

  /// Set a string
  void setString(String key, String value) {
    setBytes(key, utf8.encode(value));
  }

  /// Set bytes
  void setBytes(String key, Uint8List value) {
    _bytesMap[key] = value;
  }

  @override
  Future<String> loadString(String key) async {
    return utf8.decode(_loadBytes(key));
  }

  @override
  Future<ByteData> loadByteData(String key) async {
    return _loadBytes(key).buffer.asByteData();
  }

  Uint8List _loadBytes(String key) {
    return _bytesMap[key]!;
  }

  @override
  Future<Uint8List> loadBytes(String key) async {
    return _loadBytes(key);
  }
}
