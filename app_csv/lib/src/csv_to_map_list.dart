import 'dart:convert';

import 'package:csv/csv.dart';

/// Convert a csv (with an header row) to csv
List<Map<String, Object?>> csvToMapList(String csv,
    {CsvToListConverter? converter}) {
  if (converter == null) {
    /// Use the default eol
    csv = LineSplitter.split(csv).join(defaultEol);
    converter = const CsvToListConverter();
  }
  var rawList = converter.convert(csv);
  if (rawList.isEmpty) {
    throw UnsupportedError('csv cannot be empty');
  }

  var keys = rawList[0].cast<String>();
  var data = rawList.sublist(1);

  var list = <Map<String, Object?>>[];

  for (var row in data) {
    var map = <String, Object?>{
      for (var i = 0; i < keys.length; i++) keys[i]: row[i]
    };
    list.add(map);
  }
  return list;
}
