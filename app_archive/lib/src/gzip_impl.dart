import 'dart:convert';
import 'dart:typed_data';

import 'package:archive/archive.dart';
import 'package:tekartik_common_utils/byte_utils.dart';

/// Gzip header index 9
///
/// Unknown operating system
const gzipOperatingSystemUnknown = 255;

/// Linux operating system
const gzipOperatingSystemLinux = 3;

/// GZip some text
Uint8List gzipText(String text, {bool? noDate, int? operatingSystem}) {
  return gzipBytes(
    utf8.encode(text),
    noDate: noDate,
    operatingSystem: operatingSystem,
  );
}

/// Un Gzip some data into text
String ungzipText(Uint8List data) {
  return utf8.decode(const GZipDecoder().decodeBytes(data));
}

/// GZip some bytes
Uint8List gzipBytes(Uint8List bytes, {bool? noDate, int? operatingSystem}) {
  noDate ??= false;
  var data = const GZipEncoder().encodeBytes(bytes);
  if (noDate) {
    data[4] = 0;
    data[5] = 0;
    data[6] = 0;
    data[7] = 0;
  }
  if (operatingSystem != null) {
    data[9] = operatingSystem;
  }
  return asUint8List(data);
}

/// Un Gzip some data into bytes
/// Un Gzip some data into text
Uint8List ungzipBytes(Uint8List data) {
  return asUint8List(const GZipDecoder().decodeBytes(data));
}
