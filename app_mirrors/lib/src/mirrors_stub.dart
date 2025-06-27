import 'package:tekartik_app_mirrors/mirrors.dart';

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
ClassMirror reflectClass(Type key) =>
    throw UnsupportedError('Cannot reflectClass without dart:mirrors');

abstract class MirrorSystem {
  /// Returns the name of [symbol].
  ///
  /// The following text is non-normative:
  ///
  /// Using this method may result in larger output.  If possible, use
  /// [MirrorsUsed] to specify which symbols must be retained in clear text.
  static String getName(Symbol symbol) => throw UnsupportedError(
    'Cannot MirrorSystem.getName() without dart:mirrors',
  );
}
