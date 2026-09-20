---
name: tekartik-app-json-schema-models
description: >-
  Use when declaring a JSON schema in Dart (structured output / function
  declarations for generative AI, OpenAPI style object descriptions) with
  tekartik_app_json_schema: JsonSchema and its object/array/boolean/integer/
  number/string/enumString constructors, JsonSchemaType, toJson(),
  optionalProperties and the generated required list, the
  jsonSchemaFormatInt32/int64/float/double/enum constants, and the cv backed
  models CvJsonSchema, CvJsonSchemaBool, CvJsonSchemaInt, CvJsonSchemaNum,
  CvJsonSchemaString, CvJsonSchemaEnumString, CvJsonSchemaList, CvJsonSchemaMap
  with toJsonSchema() / toSchemaJsonMap(), from
  package:tekartik_app_json_schema/json_schema.dart and
  package:tekartik_app_json_schema/cv_json_schema.dart.
---

# JSON schema definitions (tekartik_app_json_schema)

`tekartik_app_json_schema` provides a small, dependency-free `JsonSchema` model
(the subset of OpenAPI 3.0 used by the Vertex AI / Gemini SDKs for structured
output and function declarations) plus an equivalent `cv` model tree so a
schema can itself be stored, serialized and diffed like any other `cv` model.

## Guidelines

* Dependency (git, not on pub.dev - the package lives in the
  `app_json_schema/` directory of the repo):
  ```yaml
  dependencies:
    tekartik_app_json_schema:
      git:
        url: https://github.com/tekartik/app_common_utils.dart
        path: app_json_schema
  ```
* Two imports, pick one:
  * `package:tekartik_app_json_schema/json_schema.dart` - `JsonSchema`,
    `JsonSchemaType` and the `jsonSchemaFormat*` constants. Use this when you
    just build a schema and send its `toJson()`.
  * `package:tekartik_app_json_schema/cv_json_schema.dart` - everything above
    plus the `CvJsonSchema*` models; it also re-exports `package:cv/cv_json.dart`.
* Building a schema: use the named constructors `JsonSchema.object(properties:
  {...}, optionalProperties: [...])`, `JsonSchema.array(items: ...)`,
  `JsonSchema.string()`, `JsonSchema.integer()`, `JsonSchema.number()`,
  `JsonSchema.boolean()`, `JsonSchema.enumString(enumValues: [...])`. All take
  `description:` and `nullable:`. The generic `JsonSchema(type, {...})`
  constructor exists but is rarely needed.
* `toJson()` produces the wire format: `type` upper-cased (`'STRING'`,
  `'OBJECT'`, ... via `JsonSchemaType.toJson()`), `enumValues` written as
  `enum`, and, for an object, a `required` list computed as *all properties
  minus `optionalProperties`*. So properties are required by default: list the
  optional ones in `optionalProperties`, never write `required` yourself.
  Null `format`/`description`/`nullable` are omitted.
* `format` is a plain `String?`; use the constants `jsonSchemaFormatInt32`,
  `jsonSchemaFormatInt64` (integer), `jsonSchemaFormatFloat`,
  `jsonSchemaFormatDouble` (number) and `jsonSchemaFormatEnum` (string).
  `JsonSchema.enumString` already sets the enum format.
* `JsonSchema` fields are mutable (`type`, `format`, `description`,
  `nullable`, `enumValues`, `items`, `properties`, `optionalProperties`), so a
  schema can be tweaked after construction. There is no `fromJson`: keep the
  Dart definition as the source of truth.
* The `cv` variant mirrors the same shapes as `CvModel`s: `CvJsonSchemaBool`,
  `CvJsonSchemaInt`, `CvJsonSchemaNum`, `CvJsonSchemaString`,
  `CvJsonSchemaEnumString`, `CvJsonSchemaList` (`items:`) and
  `CvJsonSchemaMap` (`properties:`, `optionalProperties:`). Read their values
  through `cv` fields (`schema.type.v`, `schema.description.v`,
  `schema.enumValues.v`, `map.properties.v`, `list.items.v`).
* `CvJsonSchemaExt` adds `toJsonSchema()` (convert to the plain `JsonSchema`)
  and `toSchemaJsonMap()` (`toMap()`, same wire format as
  `toJsonSchema().toJson()`). `CvJsonSchemaMap` also exposes the stored
  `required` field and a computed `optionalProperties` getter.
* Use the `cv` models when the schema itself must be persisted (sembast,
  firestore), copied or built dynamically; use the plain `JsonSchema` for a
  static, hand-written schema. `toJsonSchema()` throws `UnsupportedError` for
  a `CvJsonSchema` subtype it does not know.
* Anti-patterns: putting a `'required'` key in `properties`; using raw
  lowercase type strings instead of `JsonSchemaType`; assuming a property is
  optional because it is `nullable` (nullable and required are independent).

## Examples

### A structured output schema

```dart
import 'dart:convert';

import 'package:tekartik_app_json_schema/json_schema.dart';

void main() {
  var recipeSchema = JsonSchema.object(
    description: 'A cooking recipe',
    properties: {
      'name': JsonSchema.string(description: 'Recipe name'),
      'servings': JsonSchema.integer(format: jsonSchemaFormatInt32),
      'rating': JsonSchema.number(
        format: jsonSchemaFormatDouble,
        nullable: true,
      ),
      'vegetarian': JsonSchema.boolean(),
      'difficulty': JsonSchema.enumString(
        enumValues: ['easy', 'medium', 'hard'],
      ),
      'ingredients': JsonSchema.array(
        items: JsonSchema.string(),
        description: 'One line per ingredient',
      ),
    },
    // Everything not listed here ends up in the generated "required" list.
    optionalProperties: ['rating', 'vegetarian'],
  );

  print(const JsonEncoder.withIndent('  ').convert(recipeSchema.toJson()));
}
```

### Nested objects and reading back the wire format

```dart
import 'package:tekartik_app_json_schema/json_schema.dart';

void main() {
  var addressSchema = JsonSchema.object(
    properties: {
      'street': JsonSchema.string(),
      'city': JsonSchema.string(),
      'zip': JsonSchema.string(nullable: true),
    },
    optionalProperties: ['zip'],
  );
  var userSchema = JsonSchema.object(
    properties: {
      'id': JsonSchema.integer(format: jsonSchemaFormatInt64),
      'addresses': JsonSchema.array(items: addressSchema),
    },
  );

  var json = userSchema.toJson();
  print(json['type']); // OBJECT
  print(json['required']); // [id, addresses]
  print(JsonSchemaType.string.toJson()); // STRING

  // Fields stay mutable after construction.
  userSchema.description = 'A user with its addresses';
  print(userSchema.toJson()['description']);
}
```

### The same schema as cv models

```dart
import 'package:tekartik_app_json_schema/cv_json_schema.dart';

void main() {
  var schema = CvJsonSchemaMap(
    description: 'A user',
    properties: {
      'name': CvJsonSchemaString(),
      'age': CvJsonSchemaInt(format: jsonSchemaFormatInt32),
      'tags': CvJsonSchemaList(items: CvJsonSchemaString()),
      'status': CvJsonSchemaEnumString(enumValues: ['on', 'off']),
    },
    optionalProperties: ['age'],
  );

  // cv field access.
  print(schema.type.v); // JsonSchemaType.object
  print(schema.optionalProperties); // [age]
  print(schema.required.v); // [name, tags, status]

  // Both produce the same wire format.
  print(schema.toSchemaJsonMap());
  print(schema.toJsonSchema().toJson());
}
```

### Building a schema dynamically from a description

```dart
import 'package:tekartik_app_json_schema/cv_json_schema.dart';

CvJsonSchema schemaForType(String type) => switch (type) {
  'bool' => CvJsonSchemaBool(),
  'int' => CvJsonSchemaInt(format: jsonSchemaFormatInt32),
  'num' => CvJsonSchemaNum(format: jsonSchemaFormatDouble),
  _ => CvJsonSchemaString(),
};

void main() {
  var columns = {'enabled': 'bool', 'count': 'int', 'label': 'String'};
  var schema = CvJsonSchemaMap(
    properties: {
      for (var entry in columns.entries) entry.key: schemaForType(entry.value),
    },
    optionalProperties: ['label'],
  );
  var jsonSchema = schema.toJsonSchema();
  print(jsonSchema.toJson());
}
```
