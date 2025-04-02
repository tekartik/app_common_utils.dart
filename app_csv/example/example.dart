import 'dart:typed_data';

import 'package:tekartik_app_csv/app_csv.dart';

void main() {
  var list = [
    {
      'int': 1,
      'double': 2.0,
      'String': 'text',
      'bool': true,
      'Uint8List': Uint8List.fromList([1, 2, 3]),
      'null': null,
    },
  ];
  var csv = mapListToCsv(list);
  print(csv);
  var mapList = csvToMapList(csv);
  print(mapList);
}
