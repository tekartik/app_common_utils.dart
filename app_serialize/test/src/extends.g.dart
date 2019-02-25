import 'extends.dart';

Complex complexFromMap(Map<String, dynamic> map, {Complex complex}) {
  if (map == null) {
    return complex;
  }
  complex ??= Complex();

  complex.value = map['value'] as int;

  return complex;
}

Map<String, dynamic> complexToMap(Complex complex, {Map<String, dynamic> map}) {
  if (complex == null) {
    return map;
  }
  map ??= <String, dynamic>{};

  map['value'] = complex.value;

  return map;
}
