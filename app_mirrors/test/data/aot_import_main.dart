// ignore_for_file: avoid_print

// A program importing the library, compiled ahead of time by
// review_regression_test.dart.
// ignore: deprecated_member_use_from_same_package
import 'package:tekartik_app_mirrors/mirrors.dart';

class _Model {
  int? value;
}

void main() {
  try {
    print(reflectClass(_Model).declarations.length);
  } on UnsupportedError catch (e) {
    // No dart:mirrors in AOT.
    print(e);
  }
}
