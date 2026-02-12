import 'package:csv/csv.dart';

class FirstOccurrenceSettingsDetector {
  final List<String>? eols;
  final List<String>? textDelimiters;

  const FirstOccurrenceSettingsDetector({this.eols, this.textDelimiters});
}

class CsvToListConverter {
  final String? eol;
  final String? fieldDelimiter;
  final FirstOccurrenceSettingsDetector? csvSettingsDetector;
  final CsvDecoder _csvDecoder;
  CsvToListConverter({this.csvSettingsDetector, this.eol, this.fieldDelimiter})
    : _csvDecoder = CsvDecoder(fieldDelimiter: fieldDelimiter);

  List<List<T>> convert<T extends dynamic>(String csv) {
    return _csvDecoder.convert(csv).cast<List<T>>();
  }
}

class ListToCsvConverter {
  const ListToCsvConverter() : _csvEncoder = const CsvEncoder();
  final CsvEncoder _csvEncoder;

  String convert(List<List<dynamic>> rows) {
    return _csvEncoder.convert(rows);
  }
}
