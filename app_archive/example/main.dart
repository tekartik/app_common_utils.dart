// ignore_for_file: avoid_print

import 'dart:convert';
import 'dart:typed_data';

import 'package:tekartik_app_archive/gzip.dart';

void main() {
  // Text in, gzip bytes out, the same on the VM, in Flutter and on the web.
  var json = jsonEncode({'name': 'étoile', 'values': List.filled(100, 1)});
  var compressed = gzipText(json);
  print('${json.length} -> ${compressed.length} bytes');
  var decoded = jsonDecode(ungzipText(compressed)) as Map<String, Object?>;
  print(decoded['name']); // étoile

  // The same bytes at every call: no date, a fixed operating system.
  var stable = gzipText(
    json,
    noDate: true,
    operatingSystem: gzipOperatingSystemUnknown,
  );
  // Header bytes 4 to 7 (the date) and 9 (the system).
  print([...stable.sublist(4, 8), stable[9]]); // [0, 0, 0, 0, 255]

  // Damaged or non gzip data throws a FormatException.
  try {
    ungzipBytes(Uint8List.fromList([1, 2, 3]));
  } on FormatException catch (e) {
    print('invalid: ${e.message}'); // invalid: Invalid gzip data
  }
}
