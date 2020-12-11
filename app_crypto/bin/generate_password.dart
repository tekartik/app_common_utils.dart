import 'dart:math';

Future<void> main() async {
  String _toString(int codeUnit) => String.fromCharCodes([codeUnit]);
  Iterable<String> generate(String startCharacter, int count) {
    var codeUnit = startCharacter.codeUnits.first;
    return List<String>.generate(count, (index) => _toString(codeUnit + index));
  }

  var digits = generate('0', 10);
  var lower = generate('a', 26);
  var upper = generate('A', 26);
  var excluded = ['i', 'l', '1', 'L', '0', 'o', 'O'];
  var allowedChars = [...digits, ...lower, ...upper]
    ..removeWhere((element) => excluded.contains(element));
  print(allowedChars.join(''));

  var sb = StringBuffer();
  for (var i = 0; i < 32; i++) {
    var count = allowedChars.length;
    var char = allowedChars[Random().nextInt(count)];
    sb.write(char);
  }
  print(sb.toString());
}
