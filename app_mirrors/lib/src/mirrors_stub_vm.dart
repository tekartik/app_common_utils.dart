import 'package:tekartik_app_mirrors/mirrors.dart';
import 'package:tekartik_app_mirrors/src/mirrors_vm.dart' as mirrors;

/// Reflects a class declaration.
///
/// Let *C* be the original class declaration of the class represented by [key].
/// This function returns a [ClassMirror] reflecting *C*.
///
/// If [key] is not an instance of [Type], then this function throws an
/// [ArgumentError]. If [key] is the Type for dynamic or a function typedef,
/// throws an [ArgumentError].
///
/// Note that since one cannot obtain a [Type] object from another isolate, this
/// function can only be used to obtain class mirrors on classes of the current
/// isolate.
ClassMirror reflectClass(Type key) => mirrors.reflectClass(key);

abstract class MirrorSystem {
  static String getName(Symbol symbol) =>
      mirrors.MirrorSystemVm.getName(symbol);
}
