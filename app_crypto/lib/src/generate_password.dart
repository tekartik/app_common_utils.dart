import 'dart:math';

/// Generate a password for encrypt/decrypt function (32 bytes), avoiding
/// confusing characters (`0 1 i l o L O`), using [Random.secure].
String generatePassword({int length = 32}) {
  String codeUnitToString(int codeUnit) => String.fromCharCodes([codeUnit]);
  Iterable<String> generate(String startCharacter, int count) {
    var codeUnit = startCharacter.codeUnits.first;
    return List<String>.generate(
      count,
      (index) => codeUnitToString(codeUnit + index),
    );
  }

  var digits = generate('0', 10);
  var lower = generate('a', 26);
  var upper = generate('A', 26);
  var excluded = ['i', 'l', '1', 'L', '0', 'o', 'O'];
  var allowedChars = [...digits, ...lower, ...upper]
    ..removeWhere((element) => excluded.contains(element));
  //print(allowedChars.join(''));

  // A cryptographically secure generator: the result is used as a key.
  var random = Random.secure();
  var sb = StringBuffer();
  for (var i = 0; i < length; i++) {
    var count = allowedChars.length;
    var char = allowedChars[random.nextInt(count)];
    sb.write(char);
  }
  return sb.toString();
}
