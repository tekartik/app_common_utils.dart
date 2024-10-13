// ignore_for_file: avoid_print

import 'package:tekartik_app_archive/gzip.dart';
import 'package:tekartik_common_utils/byte_utils.dart';
import 'package:tekartik_common_utils/hex_utils.dart';
import 'package:tekartik_common_utils/list_utils.dart';
import 'package:tekartik_common_utils/string_utils.dart';
import 'package:test/test.dart';

extension Shuffle on String {
  /// Strings are [immutable], so this getter returns a shuffled string
  /// rather than modifying the original.
  String get shuffled => (split('')..shuffle()).join('');
}

void main() {
  group('gzip', () {
    test('compress bigbytes', () {
      var allBytes = List.generate(256, (index) => index);

      var bigBytes = asUint8List(listFlatten(
          List.generate(50000, (i) => allBytes..shuffle()).toList()));
      print(
          'bigUint8List ${bigBytes.length} ${toHexString(bigBytes.sublist(0, 128))}');
      var sw = Stopwatch()..start();

      var compressed = gzipBytes(bigBytes, noDate: true);
      sw.stop();
      print('compressed ${compressed.length} ${sw.elapsed}');
      expect(gzipBytes(bigBytes, noDate: true), compressed);
      //print('compressed ${compressed.length}');
      expect(ungzipBytes(compressed), bigBytes);
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
      //print('compressed ${compressed.length}');
      expect(ungzipText(compressed), bigText);
    });
    test('compress', () {
      expect(gzipText('étoile', noDate: true), [
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

      void roundTrip(String text) {
        expect(ungzipText(gzipText(text)), text);
      }

      roundTrip('étoile');
      var bigText =
          String.fromCharCodes(List.generate(5000000, (index) => index % 255));
      roundTrip(bigText);
      expect(gzipText(bigText).length, 33103);
    });

    test('decompress', () {
      expect(
          ungzipText(asUint8List([
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
            0
          ])),
          'étoile');
    });
  });
}
