import 'dart:typed_data';

import 'package:tekartik_app_archive/gzip.dart';
import 'package:test/test.dart';

/// Regression tests of the 2026-11-09 review.
void main() {
  test('ungzip invalid data throws', () {
    // Not gzip: it gave an empty result.
    expect(
      () => ungzipBytes(Uint8List.fromList([1, 2, 3])),
      throwsFormatException,
    );
    expect(
      () => ungzipText(Uint8List.fromList([1, 2, 3])),
      throwsFormatException,
    );
    // A gzip header only.
    expect(
      () => ungzipBytes(Uint8List.fromList([31, 139, 8, 0, 0, 0, 0, 0, 0, 3])),
      throwsFormatException,
    );
  });
  test('ungzip modified data throws', () {
    var data = gzipText('hello world', noDate: true);
    // A byte of the compressed body: it decoded to another text.
    var modified = Uint8List.fromList(data)..[12] ^= 0xff;
    expect(() => ungzipText(modified), throwsFormatException);
    // The CRC: same text, wrong checksum.
    var badCrc = Uint8List.fromList(data)..[data.length - 8] ^= 0xff;
    expect(() => ungzipText(badCrc), throwsFormatException);
    // Cut: no trailer.
    expect(
      () => ungzipText(data.sublist(0, data.length - 4)),
      throwsFormatException,
    );
    expect(ungzipText(data), 'hello world');
  });
}
