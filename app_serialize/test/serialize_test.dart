import 'package:tekartik_app_serialize/serialize.dart';
import 'package:test/test.dart';

import 'src/extends.dart';
import 'src/extends.g.dart';
import 'src/simple.dart';
import 'src/simple.g.dart';

void main() {
  test('generate fromMap/toMap', () async {
    await genSerializer(src: 'test/src/simple.dart', type: Simple);

    var simple = Simple();
    expect(simpleToMap(simple), {'value': null, 'overriden_text': null});
    expect(simpleToMap(simple, map: {'base': 1}),
        {'base': 1, 'value': null, 'overriden_text': null});
    expect(simpleToMap(simpleFromMap(simpleToMap(simple))),
        {'value': null, 'overriden_text': null});
    simple = Simple()
      ..dontIncludeIfNull = 'test1'
      ..text = 'test2'
      ..value = 3;
    expect(simpleToMap(simple),
        {'value': 3, 'overriden_text': 'test2', 'dontIncludeIfNull': 'test1'});
    expect(simpleToMap(simpleFromMap(simpleToMap(simple))),
        {'value': 3, 'overriden_text': 'test2', 'dontIncludeIfNull': 'test1'});
    expect(simpleToMap(simpleFromMap(simpleToMap(Simple()), simple: Simple())),
        {'value': null, 'overriden_text': null});
  });

  test('extends generate fromMap/toMap', () async {
    await genSerializer(src: 'test/src/extends.dart', type: Complex);
    var complex = Complex();
    expect(complexToMap(complex), {'value': null});
    expect(
        complexToMap(complexFromMap(complexToMap(complex))), {'value': null});
    complex = Complex()..value = 1;
    expect(complexToMap(complex), {'value': 1});
    expect(complexToMap(complexFromMap(complexToMap(complex))), {'value': 1});
  });
}
