import 'simple.dart';

Simple simpleFromMap(Map<String, dynamic> map, {Simple simple}) {
  if (map == null) {
    return simple;
  }
  simple ??= Simple();

  simple.value = map['value'] as int;
  simple.text = map['overriden_text'] as String;
  simple.dontIncludeIfNull = map['dontIncludeIfNull'] as String;

  return simple;
}

Map<String, dynamic> simpleToMap(Simple simple, {Map<String, dynamic> map}) {
  if (simple == null) {
    return map;
  }
  map ??= <String, dynamic>{};

  map['value'] = simple.value;
  map['overriden_text'] = simple.text;
  if (simple.dontIncludeIfNull != null) {
    map['dontIncludeIfNull'] = simple.dontIncludeIfNull;
  }

  return map;
}
