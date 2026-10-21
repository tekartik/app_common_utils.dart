import 'package:tekartik_app_pb/pb.dart';
import 'package:test/test.dart';

void main() {
  test('pbMessageToText', () {
    var message = pbDecodeMessage(
      pbEncodeMessage(
        PbMessage()
          ..addInt(1, 150)
          ..addInt(2, -1)
          ..addString(3, 'say "hi"\n\\')
          ..addMessage(4, PbMessage()..addMessage(1, PbMessage()..addInt(1, 1)))
          ..addBytes(5, [0, 1, 0xff, 0x41])
          ..addFixed32(6, 42)
          ..addFixed64(7, 42)
          ..addGroup(8, PbMessage()..addString(1, 'g'))
          ..addString(9, 'été')
          ..addString(10, ''),
      ),
    );
    expect(pbMessageToText(message), r'''
1: 150
2: 18446744073709551615
3: "say \"hi\"\n\\"
4 {
  1 {
    1: 1
  }
}
5: "\000\001\377A"
6: 0x0000002a
7: 0x000000000000002a
8 {
  1: "g"
}
9: "été"
10: ""
''');
  });

  test('embedded message built in memory', () {
    var message = PbMessage()..addMessage(1, PbMessage()..addString(1, 'a'));
    expect(pbMessageToText(message, indent: '\t'), '1 {\n\t1: "a"\n}\n');
  });

  test('escape', () {
    expect(pbEscapeString('a\tb\rc\u0001\u007f'), r'a\tb\rc\001\177');
    expect(
      pbEscapeBytes([0x22, 0x5c, 0x0a, 0x0d, 0x09, 0x7f]),
      r'\"\\\n\r\t\177',
    );
  });
}
