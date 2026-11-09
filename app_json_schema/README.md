# tekartik_app_json_schema

Declare a schema in Dart for Gemini / Vertex AI structured output and
function declarations: `JsonSchema` (the OpenAPI 3.0 subset used by the
Vertex AI SDK, copied from it, no dependency) and the same shapes as cv
models (`CvJsonSchemaMap`, `CvJsonSchemaString`...), to build a schema from
data.

## Getting started

Not on pub.dev, add it as a git dependency (Dart SDK `^3.12.0`):

```yaml
dependencies:
  tekartik_app_json_schema:
    git:
      url: https://github.com/tekartik/app_common_utils.dart
      path: app_json_schema
```

```dart
import 'package:tekartik_app_json_schema/json_schema.dart';

void main() {
  var schema = JsonSchema.object(
    properties: {
      'name': JsonSchema.string(description: 'Recipe name'),
      'servings': JsonSchema.integer(),
      'rating': JsonSchema.number(nullable: true),
    },
    optionalProperties: ['rating'],
  );
  print(schema.toJson()['required']); // [name, servings]
}
```

Pure Dart: Dart VM, Flutter (mobile, desktop, web), browser. See
[example/main.dart](example/main.dart).

## What to use

* `json_schema.dart`: `JsonSchema.object`, `.array`, `.string`,
  `.enumString`, `.integer`, `.number`, `.boolean` (all with `description`
  and `nullable`), `toJson()`; the `jsonSchemaFormat*` constants (`int32`,
  `int64`, `float`, `double`).
* `cv_json_schema.dart` (also exports `json_schema.dart`): `CvJsonSchemaMap`,
  `CvJsonSchemaList`, `CvJsonSchemaString`, `CvJsonSchemaEnumString`,
  `CvJsonSchemaInt`, `CvJsonSchemaNum`, `CvJsonSchemaBool`, then
  `toJsonSchema()` (a `JsonSchema`) or `toSchemaJsonMap()` (a map).

## Common pitfalls

* The output is the Gemini dialect (`"type": "STRING"` in upper case,
  `nullable`, `format: "enum"`), not a standard JSON Schema document (lower
  case types, no `nullable`): do not give it to a JSON Schema validator.
* Every property is required unless listed in `optionalProperties`;
  `nullable: true` does not make it optional.
* The cv models are written, not read back: `fromMap` throws
  `Missing builder for 'CvJsonSchema'`. Keep the Dart code as the source.
* `toSchemaJsonMap()` leaves out an empty `required` list, `toJson()`
  writes `"required": []`.
* A `CvJsonSchemaMap` whose properties are all optional (or empty) threw a
  null check error in `toJsonSchema()` before 2026-11-09.

## Agent skills

[skills/tekartik-app-json-schema-models](skills/tekartik-app-json-schema-models/SKILL.md).
