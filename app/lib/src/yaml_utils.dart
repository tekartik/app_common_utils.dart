import 'package:cv/cv.dart';
import 'package:yaml/yaml.dart';

/// Decode a YAML string into a Model object.
///
/// The result is a read-only view of the YAML map: nested maps are `YamlMap`
/// (read them as `Map`), a key that is not a string throws when read.
/// Throws an [ArgumentError] when the document is not a map and a
/// `YamlException` when the YAML is invalid.
Model decodeYamlMap(String yaml) {
  final map = loadYaml(yaml);
  if (map is! Map) {
    throw ArgumentError('Expected a YAML map, but got: $map');
  }

  return asModel(map);
}

/// Decode a YAML string into a Model object, or return null if the input is
/// null or the document is not a map (invalid YAML throws a `YamlException`).
///
/// See [decodeYamlMap].
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
