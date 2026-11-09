// ignore_for_file: avoid_print

// Deprecated with dart:mirrors (Dart 3.14), still working on the JIT VM.
// ignore: deprecated_member_use_from_same_package
import 'package:tekartik_app_mirrors/mirrors.dart';

/// An annotation read by the generator.
class Column {
  final String name;

  const Column(this.name);
}

class User {
  @Column('user_name')
  String? name;
  int? age;
}

/// Run with `dart run example/main.dart` (JIT VM only).
void main() {
  var classMirror = reflectClass(User);
  for (var declaration in classMirror.declarations.values) {
    if (declaration is VariableMirror) {
      var name = MirrorSystem.getName(declaration.simpleName);
      var type = declaration.type.reflectedType;
      var column = declaration.metadata
          .map((annotation) => annotation.reflectee)
          .whereType<Column>()
          .firstOrNull;
      print('$name: $type (column: ${column?.name ?? name})');
    }
  }
  // name: String (column: user_name)
  // age: int (column: age)
}
