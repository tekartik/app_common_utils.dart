/// A safe subset of `dart:mirrors` to reflect on a class (its fields, their
/// types and their annotations) from a VM tool or code generator, importable
/// from any project.
///
/// `dart:mirrors` is deprecated as of Dart 3.14, and so is this library: it
/// keeps working on the VM, new code should generate its code
/// (`build_runner`) instead.
@Deprecated(
  'dart:mirrors is deprecated as of Dart 3.14, generate the code '
  '(build_runner) instead',
)
library;

export 'src/mirrors_api.dart';
