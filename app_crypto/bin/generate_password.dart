import 'dart:io';

import 'package:tekartik_app_crypto/src/generate_password.dart';

Future<void> main() async {
  stdout.writeln(generatePassword());
}
