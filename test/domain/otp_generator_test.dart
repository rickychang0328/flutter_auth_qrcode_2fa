import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter_auth_qrcode_2fa/domain/hash_algorithm.dart';
import 'package:flutter_auth_qrcode_2fa/domain/otp_generator.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('TOTP RFC 6238', () {
    final keySha1 =
        Uint8List.fromList(utf8.encode('12345678901234567890'));
    final keySha256 =
        Uint8List.fromList(utf8.encode('12345678901234567890123456789012'));
    final keySha512 = Uint8List.fromList(utf8.encode(
      '1234567890123456789012345678901234567890123456789012345678901234',
    ));

    test('SHA1 vectors', () {
      expect(
        OtpGenerator.totpRfc6238Int(
          keySha1,
          OtpGenerator.totpDefaultPeriod,
          59,
          8,
          HashAlgorithm.sha1,
        ),
        94287082,
      );
      expect(
        OtpGenerator.totpRfc6238Int(
          keySha1,
          OtpGenerator.totpDefaultPeriod,
          1111111109,
          8,
          HashAlgorithm.sha1,
        ),
        7081804,
      );
      expect(
        OtpGenerator.totpRfc6238Int(
          keySha1,
          OtpGenerator.totpDefaultPeriod,
          1111111111,
          8,
          HashAlgorithm.sha1,
        ),
        14050471,
      );
      expect(
        OtpGenerator.totpRfc6238Int(
          keySha1,
          OtpGenerator.totpDefaultPeriod,
          1234567890,
          8,
          HashAlgorithm.sha1,
        ),
        89005924,
      );
      expect(
        OtpGenerator.totpRfc6238Int(
          keySha1,
          OtpGenerator.totpDefaultPeriod,
          2000000000,
          8,
          HashAlgorithm.sha1,
        ),
        69279037,
      );
      expect(
        OtpGenerator.totpRfc6238Int(
          keySha1,
          OtpGenerator.totpDefaultPeriod,
          20000000000,
          8,
          HashAlgorithm.sha1,
        ),
        65353130,
      );
    });

    test('SHA256 vectors', () {
      expect(
        OtpGenerator.totpRfc6238Int(
          keySha256,
          OtpGenerator.totpDefaultPeriod,
          59,
          8,
          HashAlgorithm.sha256,
        ),
        46119246,
      );
      expect(
        OtpGenerator.totpRfc6238Int(
          keySha256,
          OtpGenerator.totpDefaultPeriod,
          1234567890,
          8,
          HashAlgorithm.sha256,
        ),
        91819424,
      );
    });

    test('SHA512 vectors', () {
      expect(
        OtpGenerator.totpRfc6238Int(
          keySha512,
          OtpGenerator.totpDefaultPeriod,
          59,
          8,
          HashAlgorithm.sha512,
        ),
        90693936,
      );
      expect(
        OtpGenerator.totpRfc6238Int(
          keySha512,
          OtpGenerator.totpDefaultPeriod,
          1234567890,
          8,
          HashAlgorithm.sha512,
        ),
        93441116,
      );
    });

    test('formats with leading zeros', () {
      expect(
        OtpGenerator.totpRfc6238(
          keySha1,
          OtpGenerator.totpDefaultPeriod,
          8,
          HashAlgorithm.sha1,
          timeSeconds: 59,
        ),
        '94287082',
      );
    });
  });

  group('HOTP RFC 4226', () {
    final keySha1 =
        Uint8List.fromList(utf8.encode('12345678901234567890'));

    test('counter sequence', () {
      const expected = [
        '755224',
        '287082',
        '359152',
        '969429',
        '338314',
        '254676',
        '287922',
        '162583',
        '399871',
        '520489',
      ];
      for (var i = 0; i < expected.length; i++) {
        expect(
          OtpGenerator.hotp(keySha1, i, 6, HashAlgorithm.sha1),
          expected[i],
        );
      }
    });
  });

  group('Steam', () {
    test('uses 26-char alphabet', () {
      expect(OtpGenerator.steamChars.length, 26);
      expect(
        RegExp(r'^[23456789BCDFGHJKMNPQRTVWXY]+$')
            .hasMatch(OtpGenerator.steamChars),
        isTrue,
      );
    });

    test('deterministic output for fixed time', () {
      final secret = Uint8List.fromList([1, 2, 3, 4, 5, 6, 7, 8]);
      final a = OtpGenerator.totpSteam(
        secret,
        30,
        5,
        HashAlgorithm.sha1,
        timeSeconds: 1234567890,
      );
      final b = OtpGenerator.totpSteam(
        secret,
        30,
        5,
        HashAlgorithm.sha1,
        timeSeconds: 1234567890,
      );
      expect(a, b);
      expect(a.length, 5);
      final valid = RegExp('^[${OtpGenerator.steamChars}]+\$');
      expect(valid.hasMatch(a), isTrue);
    });
  });
}
