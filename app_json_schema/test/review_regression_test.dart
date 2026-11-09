import 'package:tekartik_app_json_schema/cv_json_schema.dart';
import 'package:test/test.dart';

/// Regression tests of the 2026-11-09 review.
void main() {
  test('object schema without required property', () {
    var schema = CvJsonSchemaMap(
      properties: {'a': CvJsonSchemaString(), 'b': CvJsonSchemaInt()},
      optionalProperties: ['a', 'b'],
    );
    expect(schema.optionalProperties, ['a', 'b']);
    expect(schema.toJsonSchema().toJson(), {
      'type': 'OBJECT',
      'properties': {
        'a': {'type': 'STRING'},
        'b': {'type': 'INTEGER'},
      },
      'required': <String>[],
    });
    expect(schema.toSchemaJsonMap(), {
      'properties': {
        'a': {'type': 'STRING'},
        'b': {'type': 'INTEGER'},
      },
      'type': 'OBJECT',
    });
  });
  test('object schema without property', () {
    var schema = CvJsonSchemaMap(properties: {});
    expect(schema.toJsonSchema().toJson(), {
      'type': 'OBJECT',
      'properties': <String, Object?>{},
      'required': <String>[],
    });
  });
}
