import 'package:tekartik_app_csv/app_csv.dart';
import 'package:test/test.dart';

Future<void> main() async {
  group('compat', () {
    test('api', () {
      csvToMapList('1,2,3', converter: CsvToListConverter());
      mapListToCsv([], converter: ListToCsvConverter());
    });
  });
}
