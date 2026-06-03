import 'dart:typed_data';

import 'package:crypto/crypto.dart';

import 'hash_algorithm.dart';

/// RFC 4226 / 6238 + Steam — aligned with Android `TokenCalculator`.
class OtpGenerator {
  static const int totpDefaultPeriod = 30;
  static const int totpDefaultDigits = 6;
  static const int hotpInitialCounter = 1;
  static const int steamDefaultDigits = 5;
  static const HashAlgorithm defaultAlgorithm = HashAlgorithm.sha1;

  /// Android `TokenCalculator.STEAMCHARS` (26 chars).
  static const String steamChars = '23456789BCDFGHJKMNPQRTVWXY';

  static int totpRfc6238Int(
    Uint8List secret,
    int period,
    int timeSeconds,
    int digits,
    HashAlgorithm algorithm,
  ) {
    final fullToken = _totp(secret, period, timeSeconds, algorithm);
    final div = _pow10(digits);
    return fullToken % div;
  }

  static String totpRfc6238(
    Uint8List secret,
    int period,
    int digits,
    HashAlgorithm algorithm, {
    int? timeSeconds,
  }) {
    final time = timeSeconds ?? DateTime.now().millisecondsSinceEpoch ~/ 1000;
    final token = totpRfc6238Int(secret, period, time, digits, algorithm);
    return _formatTokenString(token, digits);
  }

  static String hotp(
    Uint8List secret,
    int counter,
    int digits,
    HashAlgorithm algorithm,
  ) {
    final fullToken = _hotp(secret, counter, algorithm);
    final div = _pow10(digits);
    return _formatTokenString(fullToken % div, digits);
  }

  static String totpSteam(
    Uint8List secret,
    int period,
    int digits,
    HashAlgorithm algorithm, {
    int? timeSeconds,
  }) {
    final time = timeSeconds ?? DateTime.now().millisecondsSinceEpoch ~/ 1000;
    var fullToken = _totp(secret, period, time, algorithm);
    final buffer = StringBuffer();
    for (var i = 0; i < digits; i++) {
      buffer.write(steamChars[fullToken % steamChars.length]);
      fullToken ~/= steamChars.length;
    }
    return buffer.toString();
  }

  static int _totp(
    Uint8List key,
    int period,
    int timeSeconds,
    HashAlgorithm algorithm,
  ) {
    return _hotp(key, timeSeconds ~/ period, algorithm);
  }

  static int _hotp(Uint8List key, int counter, HashAlgorithm algorithm) {
    final data = ByteData(8)..setInt64(0, counter, Endian.big);
    final hash = _generateHash(algorithm, key, data.buffer.asUint8List());
    final offset = hash[hash.length - 1] & 0x0f;
    var binary = (hash[offset] & 0x7f) << 24;
    binary |= (hash[offset + 1] & 0xff) << 16;
    binary |= (hash[offset + 2] & 0xff) << 8;
    binary |= hash[offset + 3] & 0xff;
    return binary;
  }

  static List<int> _generateHash(
    HashAlgorithm algorithm,
    Uint8List key,
    Uint8List data,
  ) {
    final hmac = Hmac(_macAlgorithm(algorithm), key);
    return hmac.convert(data).bytes;
  }

  static Hash _macAlgorithm(HashAlgorithm algorithm) {
    switch (algorithm) {
      case HashAlgorithm.sha1:
        return sha1;
      case HashAlgorithm.sha256:
        return sha256;
      case HashAlgorithm.sha512:
        return sha512;
    }
  }

  static int _pow10(int digits) {
    var result = 1;
    for (var i = 0; i < digits; i++) {
      result *= 10;
    }
    return result;
  }

  /// Mirrors Android `Tools.formatTokenString` (English locale, no grouping).
  static String _formatTokenString(int token, int digits) {
    return token.toString().padLeft(digits, '0');
  }
}
