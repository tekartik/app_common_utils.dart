import 'extends.dart';

Complex complexFromMap(Map<String, dynamic> map, {Complex? complex}) {
  complex ??= Complex();

  complex.value = map['value'] as int?;

  return complex;
}

Map<String, dynamic> complexToMap(
  Complex complex, {
  Map<String, Object?>? map,
}) {
  map ??= <String, dynamic>{};

  map['value'] = complex.value;

  return map;
}
