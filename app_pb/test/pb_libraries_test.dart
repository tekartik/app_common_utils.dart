@TestOn('vm')
library;

import 'dart:io';

import 'package:path/path.dart';
import 'package:test/test.dart';

final _directiveRegExp = RegExp(
  r'''^(?:import|export)\s+'([^']+)'.*$''',
  multiLine: true,
);

/// The lib files [path] (relative to lib) reaches through its relative
/// imports and exports, itself included.
Set<String> reachedLibFiles(String path) {
  var reached = <String>{};
  void visit(String path) {
    if (!reached.add(path)) {
      return;
    }
    var content = File(join('lib', path)).readAsStringSync();
    for (var match in _directiveRegExp.allMatches(content)) {
      var uri = match.group(1)!;
      if (uri.startsWith('package:tekartik_app_pb/')) {
        visit(uri.substring('package:tekartik_app_pb/'.length));
      } else if (!uri.contains(':')) {
        visit(posix.normalize(posix.join(posix.dirname(path), uri)));
      }
    }
  }

  visit(path);
  return reached;
}

void main() {
  test('the reader does not link the writer', () {
    var reached = reachedLibFiles('pb_reader.dart');
    expect(reached, contains('src/pb_reader.dart'));
    expect(reached, isNot(contains('src/pb_writer.dart')));
  });

  test('the writer does not link the reader', () {
    var reached = reachedLibFiles('pb_writer.dart');
    expect(reached, contains('src/pb_writer.dart'));
    expect(reached, isNot(contains('src/pb_reader.dart')));
  });

  test('pb.dart links both', () {
    var reached = reachedLibFiles('pb.dart');
    expect(reached, containsAll(['src/pb_reader.dart', 'src/pb_writer.dart']));
  });
}
