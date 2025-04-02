import 'dart:mirrors' as vm;

import 'package:tekartik_app_mirrors/mirrors.dart';

abstract class MirrorSystemVm {
  static String getName(Symbol symbol) => vm.MirrorSystem.getName(symbol);
}

ClassMirror reflectClass(Type key) => _classMirror(vm.reflectClass(key));

ClassMirror _classMirror(vm.ClassMirror vmClassMirror) =>
    ClassMirrorVm(vmClassMirror);

mixin DeclarationMirrorMixin implements DeclarationMirror {
  dynamic get _vm;
  vm.DeclarationMirror get _vmDeclarationMirror => _vm as vm.DeclarationMirror;
  @override
  Symbol get simpleName => _vmDeclarationMirror.simpleName;

  List<InstanceMirror>? _metadata;
  @override
  List<InstanceMirror> get metadata =>
      _metadata ??= _vmDeclarationMirror.metadata
          .map(
            (vm.InstanceMirror vmInstanceMirror) =>
                _instanceMirror(vmInstanceMirror),
          )
          .toList(growable: false);
}

class InstanceMirrorVm with DeclarationMirrorMixin implements InstanceMirror {
  @override
  final vm.InstanceMirror _vm;

  InstanceMirrorVm(this._vm);

  @override
  ClassMirror? get type => _classMirror(_vm.type);

  @override
  dynamic get reflectee => _vm.reflectee;
}

InstanceMirror _instanceMirror(vm.InstanceMirror vmInstanceMirror) =>
    InstanceMirrorVm(vmInstanceMirror);

class ClassMirrorVm with DeclarationMirrorMixin implements ClassMirror {
  @override
  final vm.ClassMirror _vm;

  Map<Symbol, DeclarationMirror>? _declarations;

  ClassMirrorVm(this._vm);
  @override
  Map<Symbol, DeclarationMirror> get declarations =>
      _declarations ??= () {
        return _vm.declarations.map((
          symbol,
          vm.DeclarationMirror vmDeclarationMirror,
        ) {
          return MapEntry<Symbol, DeclarationMirror>(
            symbol,
            _declarationMirror(vmDeclarationMirror),
          );
        });
      }();

  @override
  Type get reflectedType => _vm.reflectedType;

  @override
  bool get hasReflectedType => _vm.hasReflectedType;

  @override
  ClassMirror? get superclass =>
      _vm.superclass == null ? null : _classMirror(_vm.superclass!);
}

class VariableMirrorVm with DeclarationMirrorMixin implements VariableMirror {
  @override
  final vm.VariableMirror _vm;

  VariableMirrorVm(this._vm);
  @override
  TypeMirror get type => wrapTypeMirror(_vm.type);
}

TypeMirror wrapTypeMirror(vm.TypeMirror vmType) => TypeMirrorVm(vmType);

class TypeMirrorVm with DeclarationMirrorMixin implements TypeMirror {
  @override
  final vm.TypeMirror _vm;

  TypeMirrorVm(this._vm);

  @override
  bool get hasReflectedType => _vm.hasReflectedType;

  @override
  Type get reflectedType => _vm.reflectedType;
}

DeclarationMirror _declarationMirror(vm.DeclarationMirror vmDeclarationMirror) {
  if (vmDeclarationMirror is vm.VariableMirror) {
    return VariableMirrorVm(vmDeclarationMirror);
  }
  return DeclarationMirrorVm(vmDeclarationMirror);
}

class DeclarationMirrorVm
    with DeclarationMirrorMixin
    implements DeclarationMirror {
  @override
  final vm.DeclarationMirror _vm;

  DeclarationMirrorVm(this._vm);
}
