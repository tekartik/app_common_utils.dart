@TestOn('vm')
import 'package:json_annotation/json_annotation.dart';
import 'package:tekartik_app_mirrors/mirrors.dart';
import 'package:test/test.dart';

class MyClass {
  int? value;
  @JsonKey(name: 'overriden_text')
  String? text;
}

class MyBaseClass {
  int? base;
}

class MySubClass extends MyBaseClass {
  int? value;
}

void main() {
  test('reflectClass', () {
    var classMirror = reflectClass(MyClass);

    //var symbol = classMirror.qualifiedName;
    var typeText = classMirror.reflectedType.toString();

    expect(classMirror.reflectedType, MyClass);
    expect(classMirror.superclass!.reflectedType, Object);

    print('Type: $typeText');

    var declarations = classMirror.declarations;
    declarations.forEach((symbol, declaration) {
      //if (declaration.isTopLevel) {
      if (declaration is VariableMirror) {
        print(declaration.type.reflectedType.toString());
        print(MirrorSystem.getName(declaration.simpleName));
        for (var instanceMirror in declaration.metadata) {
          dynamic reflectee = instanceMirror.reflectee;

          if (reflectee is JsonKey) {
            expect(reflectee.name, 'overriden_text');
            // print('meta: JsonKey(${reflectee.name})');
            //print(instanceMirror.reflectee.runtimeType);
          }
        }
      }
    });
  });

  test('super class', () {
    var classMirror = reflectClass(MySubClass);

    //var symbol = classMirror.qualifiedName;
    var typeText = classMirror.reflectedType.toString();

    expect(classMirror.reflectedType, MySubClass);
    expect(classMirror.superclass!.reflectedType, MyBaseClass);
    print('Type: $typeText');

    /*
    var instanceMembers = classMirror.instanceMembers;


    var keys = instanceMembers.keys;
    for (var key in keys) {
      var methodMirror = instanceMembers[key];
      if (methodMirror.isSynthetic) {
        print(methodMirror.returnType.reflectedType.toString());

        print(MirrorSystem.getName(methodMirror.qualifiedName));
      }

    }
    */

    var declarations = classMirror.declarations;
    declarations.forEach((symbol, declaration) {
      //if (declaration.isTopLevel) {
      if (declaration is VariableMirror) {
        print(declaration.type.reflectedType.toString());
        print(MirrorSystem.getName(declaration.simpleName));
        for (var instanceMirror in declaration.metadata) {
          dynamic reflectee = instanceMirror.reflectee;

          if (reflectee is JsonKey) {
            expect(reflectee.name, 'overriden_text');
            // print('meta: JsonKey(${reflectee.name})');
            //print(instanceMirror.reflectee.runtimeType);
          }
        }
      }
    });
  });
}
