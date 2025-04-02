import 'package:csv/csv.dart';
import 'package:csv/csv_settings_autodetection.dart';

final csvToMapListDefaultCsvSettingsDetector = FirstOccurrenceSettingsDetector(
  eols: ['\r\n', '\n'],
  textDelimiters: ['"', "'"],
);

/// Convert a csv (with an header row) to csv
List<Map<String, Object?>> csvToMapList(
  String csv, {
  CsvToListConverter? converter,
}) {
  // ignore: prefer_conditional_assignment
  if (converter == null) {
    /// Use the default eol
    // converter = const CsvToListConverter();
    /// New use detector:
    converter = CsvToListConverter(
      csvSettingsDetector: csvToMapListDefaultCsvSettingsDetector,
    );
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
      for (var i = 0; i < keys.length; i++) keys[i]: row[i],
    };
    list.add(map);
  }
  return list;
}
