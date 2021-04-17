import 'package:json_annotation/json_annotation.dart';

class Simple {
  int? value;

  @JsonKey(name: 'overriden_text')
  String? text;

  @JsonKey(includeIfNull: false)
  String? dontIncludeIfNull;
}
