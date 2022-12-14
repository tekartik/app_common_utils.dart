@TestOn('vm')
import 'dart:convert';
import 'dart:io';

import 'package:path/path.dart';
import 'package:test/test.dart';

void expectCsv(String value, String expected) {
  expect(const LineSplitter().convert(value),
      const LineSplitter().convert(expected));
}

void main() {
  group('csv_io', () {
    test('one_column_with_line_feed_gsheet', () async {
      var csv = await File(
              join('test', 'data', 'one_column_with_line_feed_gsheet.csv'))
          .readAsString();
      expect(
          csv,
          'one_column_with_line_feed\r\n'
          '"Hello\n'
          'World"');
    });
  });
}
