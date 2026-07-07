import 'package:csv/csv.dart';

/// Detector for identifying EOLs and text delimiters from the first occurrence.
class FirstOccurrenceSettingsDetector {
  /// The end-of-line markers to detect.
  final List<String>? eols;

  /// The text delimiters to detect.
  final List<String>? textDelimiters;

  /// Creates a new settings detector with optional EOLs and text delimiters.
  const FirstOccurrenceSettingsDetector({this.eols, this.textDelimiters});
}

/// Converter that translates CSV strings into lists of rows.
class CsvToListConverter {
  /// The custom end-of-line marker to use.
  final String? eol;

  /// The field delimiter to use.
  final String? fieldDelimiter;

  /// The settings detector used for auto-detecting CSV formatting.
  final FirstOccurrenceSettingsDetector? csvSettingsDetector;
  final CsvDecoder _csvDecoder;

  /// Creates a CSV-to-list converter.
  CsvToListConverter({this.csvSettingsDetector, this.eol, this.fieldDelimiter})
    : _csvDecoder = CsvDecoder(fieldDelimiter: fieldDelimiter);

  /// Converts the CSV string into a list of rows.
  List<List<T>> convert<T extends dynamic>(String csv) {
    return _csvDecoder.convert(csv).cast<List<T>>();
  }
}

/// Converter that translates lists of rows into CSV strings.
class ListToCsvConverter {
  /// Creates a list-to-CSV converter.
  const ListToCsvConverter() : _csvEncoder = const CsvEncoder();
  final CsvEncoder _csvEncoder;

  /// Converts the given rows into a CSV string.
  String convert(List<List<dynamic>> rows) {
    return _csvEncoder.convert(rows);
  }
}
