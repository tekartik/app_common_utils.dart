import 'package:cv/cv.dart';
import 'package:yaml/yaml.dart';

/// Decode a YAML string into a Model object.
Model decodeYamlMap(String yaml) {
  final map = loadYaml(yaml);
  if (map is! Map) {
    throw ArgumentError('Expected a YAML map, but got: $map');
  }
  return asModel(map);
}

/// Decode a YAML string into a Model object, or return null if the input is null or not a valid YAML map.
Model? decodeYamlMapOrNull(String? yaml) {
  if (yaml == null) {
    return null;
  }
  final map = loadYaml(yaml);
  if (map is! Map) {
    return null;
  }
  return asModel(map);
}
