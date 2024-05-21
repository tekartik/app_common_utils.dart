import 'dart:convert';

import 'package:crypto/crypto.dart';

String md5Hash(String input) {
  return md5.convert(utf8.encode(input)).toString();
}
