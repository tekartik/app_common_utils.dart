// ignore_for_file: avoid_print

import 'dart:io';

import 'package:json_annotation/json_annotation.dart';
import 'package:path/path.dart';
// Deprecated with dart:mirrors (Dart 3.14), still working on the Dart VM.
// ignore: deprecated_member_use_from_same_package
import 'package:tekartik_app_serialize/serialize.dart';

/// The model. In a real package it is in its own file, the `src` given to
/// genSerializer.
class Todo {
  int? id;

  @JsonKey(name: 'due_date')
  String? dueDate;

  @JsonKey(includeIfNull: false)
  String? note;
}

/// Run with `dart run example/main.dart` (Dart VM only).
Future<void> main() async {
  var dir = await Directory.systemTemp.createTemp('app_serialize_example');
  try {
    // The output is <dirname(src)>/todo.g.dart, importing 'todo.dart'.
    var src = join(dir.path, 'todo.dart');
    await genSerializer(src: src, type: Todo);
    print(await File(join(dir.path, 'todo.g.dart')).readAsString());
  } finally {
    await dir.delete(recursive: true);
  }
}
