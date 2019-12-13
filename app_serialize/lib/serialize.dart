import 'dart:io';

import 'package:dart_style/dart_style.dart';
import 'package:json_annotation/json_annotation.dart';
import 'package:meta/meta.dart';
import 'package:path/path.dart';
import 'package:tekartik_app_mirrors/mirrors.dart';

Future genSerializer({@required String src, @required Type type}) async {
  var classMirror = reflectClass(type);

  //var symbol = classMirror.qualifiedName;
  var typeText = classMirror.reflectedType.toString();

  var declarations = classMirror.declarations;

  final sb = StringBuffer();
  final sbTo = StringBuffer();

  final entityName =
      '${typeText.substring(0, 1).toLowerCase()}${typeText.substring(1)}';

  sb.writeln('''
  import '${basename(src)}';
  
  $typeText ${entityName}FromMap(Map<String, dynamic> map, {$typeText $entityName}) {
    if (map == null) { return ${entityName}; }
    ${entityName} ??= ${typeText}();
  ''');

  sbTo.writeln('''
  Map<String, dynamic> ${entityName}ToMap(${typeText} ${entityName}, {Map<String, dynamic> map}) {
    if (${entityName} == null) { return map; }
    map ??= <String, dynamic>{};
  ''');
  declarations.forEach((symbol, declaration) {
    //if (declaration.isTopLevel) {
    if (declaration is VariableMirror) {
      var variableTypeText = declaration.type.reflectedType.toString();
      var variableSimpleName = MirrorSystem.getName(declaration.simpleName);
      String keyName;
      bool includeIfNull;
      declaration.metadata.forEach((InstanceMirror instanceMirror) {
        dynamic reflectee = instanceMirror.reflectee;

        if (reflectee is JsonKey) {
          keyName = reflectee.name;
          includeIfNull = reflectee.includeIfNull;
        }
      });
      keyName ??= variableSimpleName;
      includeIfNull ??= true;

      sb.write('''
    ${entityName}.${variableSimpleName} = map['$keyName'] as ${variableTypeText};
  ''');

      if (!includeIfNull) {
        sbTo.writeln('if (${entityName}.${variableSimpleName} != null) {');
      }
      sbTo.write('''
    map['$keyName'] = ${entityName}.$variableSimpleName;
  ''');
      if (!includeIfNull) {
        sbTo.writeln('}');
      }
    }
  });
  sb.writeln('''
  
    return ${entityName};
  }
  ''');

  sbTo.writeln('''
  
    return map;
  }
  ''');

  sb.writeln(sbTo);

  var formatter = DartFormatter(fixes: StyleFix.all);
  // print(sb);
  var formatted = formatter.format(sb.toString(), uri: Uri.file(src));
  // print(formatted);
  await File(join(dirname(src), '${basenameWithoutExtension(src)}.g.dart'))
      .writeAsString(formatted);
}
