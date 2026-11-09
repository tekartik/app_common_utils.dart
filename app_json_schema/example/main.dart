// ignore_for_file: avoid_print

import 'dart:convert';

import 'package:tekartik_app_json_schema/cv_json_schema.dart';

void main() {
  // A structured output schema: every property is required unless listed
  // in optionalProperties.
  var recipe = JsonSchema.object(
    description: 'A cooking recipe',
    properties: {
      'name': JsonSchema.string(description: 'Recipe name'),
      'servings': JsonSchema.integer(format: jsonSchemaFormatInt32),
      'difficulty': JsonSchema.enumString(enumValues: ['easy', 'hard']),
      'ingredients': JsonSchema.array(items: JsonSchema.string()),
      'rating': JsonSchema.number(nullable: true),
    },
    optionalProperties: ['rating'],
  );
  print(jsonEncode(recipe.toJson()));
  // {"type":"OBJECT","description":"A cooking recipe","properties":{...},
  // "required":["name","servings","difficulty","ingredients"]}

  // The same shape as cv models, handy to build a schema from data.
  var columns = {'enabled': 'bool', 'count': 'int', 'label': 'string'};
  var table = CvJsonSchemaMap(
    properties: {
      for (var MapEntry(:key, :value) in columns.entries)
        key: switch (value) {
          'bool' => CvJsonSchemaBool(),
          'int' => CvJsonSchemaInt(),
          _ => CvJsonSchemaString(),
        },
    },
    optionalProperties: ['label'],
  );
  print(jsonEncode(table.toJsonSchema().toJson()));
  // {"type":"OBJECT","properties":{"enabled":{"type":"BOOLEAN"},...},
  // "required":["enabled","count"]}
}
