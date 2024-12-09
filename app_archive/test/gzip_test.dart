// ignore_for_file: avoid_print

import 'dart:typed_data';

import 'package:tekartik_app_archive/gzip.dart';
import 'package:tekartik_common_utils/byte_utils.dart';
import 'package:tekartik_common_utils/hex_utils.dart';
import 'package:tekartik_common_utils/list_utils.dart';
import 'package:tekartik_common_utils/log_format.dart';
import 'package:tekartik_common_utils/string_utils.dart';
import 'package:test/test.dart';

extension Shuffle on String {
  /// Strings are [immutable], so this getter returns a shuffled string
  /// rather than modifying the original.
  String get shuffled => (split('')..shuffle()).join('');
}

void main() {
  group('gzip', () {
    test('no date compress bigbytes', () {
      var allBytes = List.generate(256, (index) => index);

      var bigBytes = asUint8List(listFlatten(
          List.generate(50000, (i) => allBytes..shuffle()).toList()));
      print(
          'bigUint8List ${bigBytes.length} ${toHexString(bigBytes.sublist(0, 128))}');
      var sw = Stopwatch()..start();

      var compressed = gzipBytes(bigBytes, noDate: true);
      sw.stop();
      print('compressed ${compressed.length} ${sw.elapsed}');
      expect(ungzipBytes(compressed), bigBytes);

      expect(gzipBytes(bigBytes, noDate: true), compressed);
      var result = ungzipBytes(compressed);
      expect(result, bigBytes,
          reason: '${logFormat(result)} != ${logFormat(bigBytes)}');
    });
    test('compress bigbytes', () {
      var allBytes = List.generate(256, (index) => index);

      var bigBytes = asUint8List(listFlatten(
          List.generate(50000, (i) => allBytes..shuffle()).toList()));
      print(
          'bigUint8List ${bigBytes.length} ${toHexString(bigBytes.sublist(0, 128))}');
      var sw = Stopwatch()..start();

      var compressed = gzipBytes(bigBytes);
      sw.stop();
      print('compressed ${compressed.length} ${sw.elapsed}');
      var result = ungzipBytes(compressed);
      expect(result, bigBytes,
          reason: '${logFormat(result)} != ${logFormat(bigBytes)}');
    });
    test('compress bigtext', () {
      var text = 'abcdedfghijklmnopqrstuvwxyz';
      var bigText = List.generate(50000, (i) => text.shuffled).join();
      print('bigText ${bigText.length} ${bigText.truncate(128)}');
      var sw = Stopwatch()..start();
      var compressed = gzipText(bigText, noDate: true);
      sw.stop();
      print('compressed ${compressed.length} ${sw.elapsed}');
      expect(gzipText(bigText, noDate: true), compressed);
      var result = ungzipText(compressed);
      expect(result, bigText,
          reason: '${logFormat(result)} != ${logFormat(bigText)}');
    });
    String generateBigText(int alphabetCount) {
      var text = 'abcdedfghijklmnopqrstuvwxyz';
      return List.generate(alphabetCount, (i) => text.shuffled).join();
    }

    test('no date compress bigtext', () {
      var text = 'abcdedfghijklmnopqrstuvwxyz';
      var bigText = List.generate(50000, (i) => text.shuffled).join();
      print('bigText ${bigText.length} ${bigText.truncate(128)}');
      var sw = Stopwatch()..start();
      var compressed = gzipText(bigText);
      sw.stop();
      print('compressed ${compressed.length} ${sw.elapsed}');
      var result = ungzipText(compressed);
      expect(result, bigText,
          reason: '${logFormat(result)} != ${logFormat(bigText)}');
    });

    test('compress latest', () {
      expect(
          gzipText('étoile',
              noDate: true, operatingSystem: gzipOperatingSystemLinux),
          gzipBytesV2Linux);

      void roundTrip(String text) {
        var result = ungzipText(gzipText(text));
        expect(result, text,
            reason: '${logFormat(result)} != ${logFormat(text)}');
      }

      roundTrip('étoile');
      var bigText = generateBigText(500000);
      /*String.fromCharCodes(List.generate(
          // 5000000 failing on chrome
          50,
          (index) => index % 255));*/
      roundTrip(bigText);
      //expect(gzipText(bigText).length, 3689); // 33103);
    });

    test('decompress', () {
      expect(gzipBytesV2Linux, isNot(gzipBytesV1));
      expect(ungzipText(gzipBytesV1), 'étoile');
      expect(ungzipText(gzipBytesV2Linux), 'étoile');
    });
  });
}

var gzipBytesV1 = asUint8List([
  31,
  139,
  8,
  0,
  0,
  0,
  0,
  0,
  0,
  255,
  59,
  188,
  178,
  36,
  63,
  51,
  39,
  21,
  0,
  199,
  250,
  11,
  130,
  7,
  0,
  0,
  0,
]);
var gzipBytesV2Linux = () {
  var bytes = Uint8List.fromList(gzipBytesV1);
  bytes[9] = gzipOperatingSystemLinux;
  return bytes;
}();
