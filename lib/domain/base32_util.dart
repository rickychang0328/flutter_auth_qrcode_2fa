import 'dart:typed_data';

import 'package:base32/base32.dart';

/// Apache Commons Base32–compatible helpers (Android `Entry` / export).
class Base32Util {
  static final RegExp secretPattern = RegExp(r'^[a-zA-Z2-7]{2,}$');

  static Uint8List decode(String secret) {
    return Uint8List.fromList(base32.decode(secret.toUpperCase()));
  }

  static String encode(Uint8List secret, {bool stripPadding = false}) {
    final encoded = base32.encode(secret).toUpperCase();
    return stripPadding ? encoded.replaceAll('=', '') : encoded;
  }

  static bool isValidSecret(String secret) => secretPattern.hasMatch(secret);
}
