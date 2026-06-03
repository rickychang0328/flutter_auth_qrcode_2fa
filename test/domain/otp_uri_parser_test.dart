import 'package:flutter_auth_qrcode_2fa/domain/base32_util.dart';
import 'package:flutter_auth_qrcode_2fa/domain/hash_algorithm.dart';
import 'package:flutter_auth_qrcode_2fa/domain/otp_account.dart';
import 'package:flutter_auth_qrcode_2fa/domain/otp_type.dart';
import 'package:flutter_auth_qrcode_2fa/domain/otp_uri_parser.dart';
import 'package:flutter_auth_qrcode_2fa/domain/third_party_action.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const wikiSecret = 'HXDMVJECJJWSRB3HWIZR4IFUGFTMXBOZ';

  group('parseIssuerAccountFromLabel', () {
    test('single colon splits issuer and account', () {
      final r = OtpUriParser.parseIssuerAccountFromLabel(
        'ACME Co:john.doe@email.com',
      );
      expect(r.issuer, 'ACME Co');
      expect(r.account, 'john.doe@email.com');
    });

    test('multiple colons keeps whole label as account', () {
      final r = OtpUriParser.parseIssuerAccountFromLabel('a:b:c');
      expect(r.issuer, '');
      expect(r.account, 'a:b:c');
    });

    test('empty issuer part treats as account only', () {
      final r = OtpUriParser.parseIssuerAccountFromLabel(':account');
      expect(r.issuer, '');
      expect(r.account, ':account');
    });
  });

  group('OtpUriParser.parse', () {
    test('rejects invalid inputs', () {
      expect(
        () => OtpUriParser.parse("DON'T CARE"),
        throwsA(isA<FormatException>()),
      );
      expect(
        () => OtpUriParser.parse('https://github.com/0xbb/'),
        throwsA(isA<FormatException>()),
      );
      expect(
        () => OtpUriParser.parse(
          'otpauth://hotp/ACME%20Co:john.doe@email.com?secret=$wikiSecret',
        ),
        returnsNormally,
      );
      expect(
        () => OtpUriParser.parse('otpauth://totp/ACME'),
        throwsA(isA<FormatException>()),
      );
    });

    test('standard totp URI (andOTP / wiki vector)', () {
      final account = OtpAccount.fromUri(
        'otpauth://totp/ACME%20Co:john.doe@email.com?secret=$wikiSecret'
        '&issuer=ACME%20Co&ALGORITHM=SHA1&digits=6&period=30',
      );
      expect(account.type, OtpType.totp);
      expect(account.label, 'ACME Co:john.doe@email.com');
      expect(account.issuer, 'ACME Co');
      expect(account.account, 'john.doe@email.com');
      expect(account.secretText, wikiSecret);
      expect(account.algorithm, HashAlgorithm.sha1);
      expect(account.period, 30);
      expect(account.digits, 6);
      expect(
        Base32Util.encode(account.secret),
        wikiSecret,
      );
    });

    test('mustauth scheme normalized like otpauth', () {
      final account = OtpAccount.fromUri(
        'mustauth://totp/Google:levi@gmail.com?secret=$wikiSecret'
        '&issuer=Google&algorithm=SHA1&digits=6&period=30&action=set',
      );
      expect(account.issuer, 'Google');
      expect(account.account, 'levi@gmail.com');
      expect(account.action, ThirdPartyAction.create);
    });

    test('scheme prefix case normalized', () {
      final account = OtpAccount.fromUri(
        'OTPAuth://totp/test-user?secret=$wikiSecret',
      );
      expect(account.secretText, wikiSecret);
      expect(account.account, 'test-user');
    });

    test('action=get maps to copy', () {
      final account = OtpAccount.fromUri(
        'otpauth://totp/user?secret=$wikiSecret&action=get',
      );
      expect(account.action, ThirdPartyAction.copy);
    });

    test('duplicate tags and groups', () {
      final account = OtpAccount.fromUri(
        'otpauth://totp/ACME%20Co:john.doe@email.com?secret=$wikiSecret'
        '&issuer=ACME%20Co&ALGORITHM=SHA1&digits=6&period=30'
        '&tags=test1&tags=test2&group=1&group=2',
      );
      expect(account.tags, ['test1', 'test2']);
      expect(account.groupList, ['1', '2']);
    });

    test('invalid host uppercase throws', () {
      expect(
        () => OtpUriParser.parse(
          'otpauth://TOTP/user?secret=$wikiSecret',
        ),
        throwsA(
          predicate<FormatException>(
            (e) => e.message == OtpUriParser.invalidHost,
          ),
        ),
      );
    });

    test('unknown lowercase host rewrites to totp path', () {
      final parsed = OtpUriParser.parse(
        'otpauth://customhost/my-label?secret=$wikiSecret',
      );
      expect(parsed.type, OtpType.totp);
      expect(parsed.label, contains('my-label'));
    });
  });
}
