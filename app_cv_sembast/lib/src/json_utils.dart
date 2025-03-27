import 'dart:convert';

import 'package:cv/cv_json.dart';
import 'package:sembast/utils/type_adapter.dart';
import 'package:tekartik_app_cv_sembast/app_cv_sembast.dart';

/// Easy extension
extension DbRecordJsonExt<K, V> on DbRecord<K> {
  /// to json encodable
  Model dbToJsonEncodable(
      {List<String>? columns,
      bool includeMissingValue = false,
      JsonEncodableCodec? codec}) {
    return (codec ?? sembastDefaultJsonEncodableCodec).encode(
            toMap(columns: columns, includeMissingValue: includeMissingValue))
        as Model;
  }

  /// to json helper.
  String dbToJson(
          {JsonEncodableCodec? codec,
          List<String>? columns,
          bool includeMissingValue = false}) =>
      jsonEncode(
        dbToJsonEncodable(
            codec: codec,
            columns: columns,
            includeMissingValue: includeMissingValue),
      );

  /// to json helper.
  String dbToJsonPretty({
    JsonEncodableCodec? codec,
    List<String>? columns,
    bool includeMissingValue = false,
  }) =>
      jsonPrettyEncode(
        dbToJsonEncodable(
            codec: codec,
            columns: columns,
            includeMissingValue: includeMissingValue),
      );
}

/// Easy extension
extension DbRecordListJsonExt<K, V> on List<DbRecord<K>> {
  /// to json encodable
  List<Model> dbToJsonEncodable(
          {List<String>? columns,
          bool includeMissingValue = false,
          JsonEncodableCodec? codec}) =>
      map((item) => item.dbToJsonEncodable(
          columns: columns,
          includeMissingValue: includeMissingValue,
          codec: codec)).toList();

  /// to json helper.
  String dbToJson(
          {JsonEncodableCodec? codec,
          List<String>? columns,
          bool includeMissingValue = false}) =>
      jsonEncode(
        dbToJsonEncodable(
            codec: codec,
            columns: columns,
            includeMissingValue: includeMissingValue),
      );

  /// to json helper using 2 spaces indent.
  String dbToJsonPretty({
    JsonEncodableCodec? codec,
    List<String>? columns,
    bool includeMissingValue = false,
  }) =>
      jsonPrettyEncode(
        dbToJsonEncodable(
            codec: codec,
            columns: columns,
            includeMissingValue: includeMissingValue),
      );
}
