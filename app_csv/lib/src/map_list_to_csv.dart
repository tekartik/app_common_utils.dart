import 'package:csv/csv.dart';

/// Convert a map list to csv
///
/// if [columns] is set columns are set first and always present
String mapListToCsv(
  List<Map> mapList, {
  ListToCsvConverter? converter,
  Object? nullValue = '',
  List<String>? columns,
}) {
  converter ??= const ListToCsvConverter();
  var data = <List>[];
  var keys = <String>[];
  var keyIndexMap = <String, int>{};

  // Add the key and fix previous records
  int addKey(String key) {
    var index = keys.length;
    keyIndexMap[key] = index;
    keys.add(key);
    for (var dataRow in data) {
      dataRow.add(nullValue);
    }
    return index;
  }

  // Add columns first if specified
  if (columns != null) {
    for (var column in columns) {
      addKey(column);
    }
  }

  for (var map in mapList) {
    // This list might grow if a new key is found
    var dataRow = List.filled(keyIndexMap.length, nullValue, growable: true);
    // Fix missing key
    map.forEach((key, value) {
      value ??= nullValue;
      var keyIndex = keyIndexMap[key];
      if (keyIndex == null) {
        // New key is found
        // Add it and fix previous data
        keyIndex = addKey(key.toString());
        // grow our list
        dataRow = List.from(dataRow, growable: true)..add(value);
      } else {
        dataRow[keyIndex] = value;
      }
    });
    data.add(dataRow);
  }
  return converter.convert(<List>[keys, ...data]);
}
