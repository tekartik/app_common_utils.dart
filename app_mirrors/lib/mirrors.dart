import 'package:tekartik_app_mirrors/src/mirrors.dart' as mirrors;

/// A [MirrorSystem] is the main interface used to reflect on a set of
/// associated libraries.
///
/// At runtime each running isolate has a distinct [MirrorSystem].
///
/// It is also possible to have a [MirrorSystem] which represents a set
/// of libraries which are not running -- perhaps at compile-time.  In
/// this case, all available reflective functionality would be
/// supported, but runtime functionality (such as invoking a function
/// or inspecting the contents of a variable) would fail dynamically.
abstract class MirrorSystem {
  /// Returns the name of [symbol].
  ///
  /// The following text is non-normative:
  ///
  /// Using this method may result in larger output.  If possible, use
  /// [MirrorsUsed] to specify which symbols must be retained in clear text.
  static String getName(Symbol symbol) => mirrors.MirrorSystem.getName(symbol);
}

///
/// A [Mirror] reflects some Dart language entity.
///
/// Every [Mirror] originates from some [MirrorSystem].
///
abstract class Mirror {}

/// Unused
abstract class ObjectMirror {}

/// An [InstanceMirror] reflects an instance of a Dart language object.
abstract class InstanceMirror implements ObjectMirror {
  /// A mirror on the type of the reflectee.
  ///
  /// Returns a mirror on the actual class of the reflectee.
  /// The class of the reflectee may differ from
  /// the object returned by invoking [runtimeType] on
  /// the reflectee.
  ClassMirror? get type;

  /// If the [InstanceMirror] reflects an instance it is meaningful to
  /// have a local reference to, we provide access to the actual
  /// instance here.
  ///
  /// If you access [reflectee] when [hasReflectee] is false, an
  /// exception is thrown.
  dynamic get reflectee;
}

///
/// A [DeclarationMirror] reflects some entity declared in a Dart program.
///
abstract class DeclarationMirror implements Mirror {
  ///
  /// The simple name for this Dart language entity.
  ///
  /// The simple name is in most cases the identifier name of the entity,
  ///such as 'myMethod' for a method, [:void myMethod() {...}:] or 'mylibrary'
  /// for a [:library 'mylibrary';:] declaration.
  ///
  Symbol get simpleName;

  /// A list of the metadata associated with this declaration.
  ///
  /// Let *D* be the declaration this mirror reflects.
  /// If *D* is decorated with annotations *A1, ..., An*
  /// where *n > 0*, then for each annotation *Ai* associated
  /// with *D, 1 <= i <= n*, let *ci* be the constant object
  /// specified by *Ai*. Then this method returns a list whose
  /// members are instance mirrors on *c1, ..., cn*.
  /// If no annotations are associated with *D*, then
  /// an empty list is returned.
  ///
  /// If evaluating any of *c1, ..., cn* would cause a
  /// compilation error
  /// the effect is the same as if a non-reflective compilation error
  /// had been encountered.
  List<InstanceMirror> get metadata;
}

///
/// A [ClassMirror] reflects a Dart language class.
///
abstract class ClassMirror implements TypeMirror {
  /// A mirror on the superclass on the reflectee.
  ///
  /// If this type is [:Object:], the superclass will be null.
  ClassMirror? get superclass;

  ///
  /// Returns an immutable map of the declarations actually given in the class
  /// declaration.
  ///
  /// This map includes all regular methods, getters, setters, fields,
  /// constructors and type variables actually declared in the class. Both
  /// static and instance members are included, but no inherited members are
  /// included. The map is keyed by the simple names of the declarations.
  ///
  /// This does not include inherited members.
  ///
  Map<Symbol, DeclarationMirror> get declarations;
}

///
/// A [VariableMirror] reflects a Dart language variable declaration.
///
abstract class VariableMirror implements DeclarationMirror {
  /// Returns a mirror on the type of the reflectee.
  TypeMirror get type;
}

///
/// A [TypeMirror] reflects a Dart language class, typedef,
/// function type or type variable.
///
abstract class TypeMirror implements DeclarationMirror {
  ///
  /// Returns true if this mirror reflects dynamic, a non-generic class or
  /// typedef, or an instantiated generic class or typedef in the current
  /// isolate. Otherwise, returns false.
  ///
  bool get hasReflectedType;

  ///
  /// If [:hasReflectedType:] returns true, returns the corresponding [Type].
  /// Otherwise, an [UnsupportedError] is thrown.
  ///
  Type get reflectedType;
}

///
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
///
ClassMirror reflectClass(Type key) => mirrors.reflectClass(key);
