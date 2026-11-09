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
///
/// Throws an `ArchiveException` (a [FormatException]) for data that is not
/// valid gzip (bad header, cut or modified data), a [FormatException] for
/// bytes that are not UTF-8.
String ungzipText(Uint8List data) {
  return utf8.decode(_ungzip(data));
}

/// Checked: without `verify`, archive 4 returns empty, partial or wrong
/// bytes for invalid data instead of throwing.
List<int> _ungzip(Uint8List data) =>
    const GZipDecoder().decodeBytes(data, verify: true);

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
///
/// Throws an `ArchiveException` (a [FormatException]) for data that is not
/// valid gzip (bad header, cut or modified data).
Uint8List ungzipBytes(Uint8List data) {
  return asUint8List(_ungzip(data));
}
