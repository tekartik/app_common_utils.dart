import 'dart:convert';
import 'dart:typed_data';

import 'package:archive/archive.dart';
import 'package:tekartik_common_utils/byte_utils.dart';

/// GZip some text
Uint8List gzipText(String text, {bool? noDate}) {
  noDate ??= false;
  var data = const GZipEncoder().encode(utf8.encode(text));
  if (noDate) {
    data[4] = 0;
    data[5] = 0;
    data[6] = 0;
    data[7] = 0;
  }
  return asUint8List(data);
}

/// Un Gzip some data into text
String ungzipText(Uint8List data) {
  return utf8.decode(const GZipDecoder().decodeBytes(data));
}

/// GZip some bytes
Uint8List gzipBytes(Uint8List bytes, {bool? noDate}) {
  noDate ??= false;
  var data = const GZipEncoder().encode(bytes);
  if (noDate) {
    data[4] = 0;
    data[5] = 0;
    data[6] = 0;
    data[7] = 0;
  }
  return asUint8List(data);
}

/// Un Gzip some data into bytes
/// Un Gzip some data into text
Uint8List ungzipBytes(Uint8List data) {
  return asUint8List(const GZipDecoder().decodeBytes(data));
}
