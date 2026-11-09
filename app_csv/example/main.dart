// ignore_for_file: avoid_print

import 'dart:convert';
import 'dart:typed_data';

import 'package:tekartik_app_csv/app_csv.dart';

void main() {
  // Map list to csv: the header is the union of the keys.
  var list = <Map<String, Object?>>[
    {'id': 1, 'name': 'Alice', 'note': 'likes "csv", a lot'},
    {
      'id': 2,
      'name': 'Bob',
      'bytes': Uint8List.fromList([1, 2, 3]),
    },
  ];
  var csv = mapListToCsv(list);
  print(csv);
  // id,name,note,bytes
  // 1,Alice,"likes ""csv"", a lot",
  // 2,Bob,,"[1, 2, 3]"

  // Csv to map list: every value is a String.
  var back = csvToMapList(csv);
  print(back.first['id']); // '1'
  print(int.parse(back.first['id'] as String) + 1); // 2

  // A known delimiter (French Excel uses ';'), a short row.
  var rows = csvToMapList(
    'sku;price\r\nA1;9,5\r\nB2\r\n',
    converter: CsvToListConverter(fieldDelimiter: ';'),
  );
  print(rows); // [{sku: A1, price: 9,5}, {sku: B2, price: null}]

  // For Excel: UTF-8 bytes prefixed with a byte order mark.
  var bytes = [...csvExcelCompatibilityBom, ...utf8.encode(csv)];
  print(bytes.length);
}
