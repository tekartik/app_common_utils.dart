import 'package:tekartik_app_csv/app_csv.dart';
import 'package:test/test.dart';

Future<void> main() async {
  group('compat', () {
    test('api', () {
      csvToMapList('', converter: CsvToListConverter());
      mapListToCsv([], converter: ListToCsvConverter());
    });
  });
}
