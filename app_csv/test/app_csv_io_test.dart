@TestOn('vm')
library;

import 'dart:io';

import 'package:path/path.dart';
import 'package:tekartik_app_csv/app_csv.dart';
import 'package:tekartik_common_utils/common_utils_import.dart';
import 'package:tekartik_common_utils/env_utils.dart';
import 'package:test/test.dart';

void expectCsv(String value, String expected) {
  expect(
    const LineSplitter().convert(value),
    const LineSplitter().convert(expected),
  );
}

void main() {
  group('csv_io', () {
    var outputDirExists = false;
    var outdir = Directory(join('.dart_tool', 'tekartik_app_csv_test', 'out'));

    Future<void> writeJson(String filename, Object data) async {
      try {
        if (!outputDirExists) {
          outdir.createSync(recursive: true);
          outputDirExists = true;
        }
        await File(
          join(outdir.path, filename),
        ).writeAsString(jsonPretty(jsonEncode(data))!);
      } catch (e) {
        if (isDebug) {
          print(e);
          rethrow;
        }
      }
    }

    Future<void> writeLocalResult(String filename, String csv) async {
      var result = csvToMapList(csv);
      await writeJson('${basename(filename)}.json', result);
      result = csvToMapList(csv, converter: CsvToListConverter());
      await writeJson('${basename(filename)}_1.json', result);
      if (!Platform.isWindows) {
        result = csvToMapList(csv, converter: CsvToListConverter(eol: '\n'));
        await writeJson('${basename(filename)}_2.json', result);
      }
    }

    /// Read input data.
    Future<String> readCsv(String filename) async {
      var csv = await File(join('test', 'data', filename)).readAsString();
      if (isDebug) {
        await writeLocalResult(filename, csv);
      }
      return csv;
    }

    test('one_column_with_line_feed_gsheet', () async {
      var csv = await readCsv('one_column_with_line_feed_gsheet.csv');
      // print(utf8.encode(csv));
      try {
        expect(
          csv,
          'one_column_with_line_feed\r\n'
          '"Hello\n'
          'World"',
        );
      } catch (_) {
        if (Platform.isWindows) {
          // git issue!
          expect(
            csv,
            'one_column_with_line_feed\r\n'
            '"Hello\r\n'
            'World"',
          );
        } else {
          // git issue!
          expect(
            csv,
            'one_column_with_line_feed\n'
            '"Hello\n'
            'World"',
          );
        }
      }
      if (Platform.isWindows) {
        expect(csvToMapList(csv), [
          {
            'one_column_with_line_feed':
                'Hello\r\n'
                'World',
          },
        ]);
        expect(csvToMapList(csv, converter: CsvToListConverter(eol: '\n')), [
          {
            'one_column_with_line_feed\r':
                'Hello\r\n'
                'World',
          },
        ]);
      } else {
        expect(csvToMapList(csv), [
          {
            'one_column_with_line_feed':
                'Hello\n'
                'World',
          },
        ]);
        expect(csvToMapList(csv, converter: CsvToListConverter()), [
          {
            'one_column_with_line_feed':
                'Hello\n'
                'World',
          },
        ]);
      }
    });

    test('simple1', () async {
      var csv = await readCsv('simple1.csv');
      expect(csvToMapList(csv), [
        {'a': '1', 'b': '2'},
      ]);
    });
    test('complex1', () async {
      var csv = await readCsv('complex1.csv');
      if (!Platform.isWindows) {
        expect(csvToMapList(csv), [
          {
            'L1\n'
                    'L2':
                'C1',
            'N': '0',
            'Name':
                'L1\n'
                'L2 ',
            'With space ': '12345',
            'YES = 1\n'
                    '/\n'
                    'NO = 0':
                '1',
          },
          {
            'L1\n'
                    'L2':
                '',
            'N': '0',
            'Name': 'P',
            'With space ': '',
            'YES = 1\n'
                    '/\n'
                    'NO = 0':
                '',
          },
          {
            'L1\n'
                    'L2':
                'C1',
            'N': 'C2',
            'Name': 'C3',
            'With space ': 'C4',
            'YES = 1\n'
                    '/\n'
                    'NO = 0':
                'C5',
          },
          {
            'L1\n'
                    'L2':
                '',
            'N': '',
            'Name': '',
            'With space ': '',
            'YES = 1\n'
                    '/\n'
                    'NO = 0':
                '86',
          },
        ]);
      }
    });

    test('local', () async {
      var src = Directory(join('test', 'data', '.local'));
      if (src.existsSync()) {
        for (var file in src.listSync().where(
          (element) => extension(element.path) == '.csv',
        )) {
          var csv = (file as File).readAsStringSync();
          await writeLocalResult(basename(file.path), csv);
        }
      }
    });
  });
}
