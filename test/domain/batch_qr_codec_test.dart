import 'package:flutter_auth_qrcode_2fa/domain/batch_qr_codec.dart';
import 'package:flutter_auth_qrcode_2fa/domain/group_model.dart';
import 'package:flutter_auth_qrcode_2fa/domain/hash_algorithm.dart';
import 'package:flutter_auth_qrcode_2fa/domain/otp_account.dart';
import 'package:flutter_auth_qrcode_2fa/domain/otp_type.dart';
import 'package:flutter_auth_qrcode_2fa/domain/base32_util.dart';
import 'package:flutter_test/flutter_test.dart';

OtpAccount _sampleAccount({
  required int lastUsed,
  required String account,
  String issuer = 'Google',
}) {
  const secretText = 'HXDMVJECJJWSRB3HWIZR4IFUGFTMXBOZ';
  return OtpAccount(
    type: OtpType.totp,
    secret: Base32Util.decode(secretText),
    secretText: secretText,
    issuer: issuer,
    account: account,
    label: '$issuer:$account',
    lastUsed: lastUsed,
    period: 30,
    digits: 6,
    algorithm: HashAlgorithm.sha1,
  );
}

void main() {
  group('BatchQrCodec.generateQrCodeStrings', () {
    test('empty list returns empty', () {
      expect(BatchQrCodec.generateQrCodeStrings([]), isEmpty);
    });

    test('single account produces one QR with header', () {
      final qr = BatchQrCodec.generateQrCodeStrings([
        _sampleAccount(lastUsed: 1, account: 'levi@gmail.com'),
      ]);
      expect(qr.length, 1);
      expect(qr.first, startsWith(
        'mustauth://mulitpleshare/mulitpleshare?action=mulitpleshare',
      ));
      expect(qr.first, contains('&mulitpleURL='));
    });

    test('nine accounts split into two QR strings', () {
      final accounts = List.generate(
        9,
        (i) => _sampleAccount(lastUsed: i + 1, account: 'user$i@test.com'),
      );
      final qr = BatchQrCodec.generateQrCodeStrings(accounts);
      expect(qr.length, 2);
      expect(
        Uri.parse(qr[0]).queryParametersAll['mulitpleURL']?.length,
        8,
      );
      expect(
        Uri.parse(qr[1]).queryParametersAll['mulitpleURL']?.length,
        1,
      );
    });

    test('attaches group query from GroupModel', () {
      final account = _sampleAccount(lastUsed: 42, account: 'levi@gmail.com');
      final groups = [
        GroupModel(id: 1, text: '1', codeLastIdList: [42]),
        GroupModel(id: 2, text: '2', codeLastIdList: [42]),
      ];
      final qr = BatchQrCodec.generateQrCodeStrings(
        [account],
        groups: groups,
      );
      final urls = Uri.parse(qr.first).queryParametersAll['mulitpleURL']!;
      final decoded = Uri.decodeComponent(urls.first);
      expect(decoded, contains('&group=1'));
      expect(decoded, contains('&group=2'));
    });

    test('export appends trailing colon when account has one colon', () {
      final account = _sampleAccount(
        lastUsed: 1,
        account: 'levi@gmail.com',
        issuer: 'Google',
      );
      account.account = 'Google:levi@gmail.com';
      final qr = BatchQrCodec.generateQrCodeStrings([account]);
      final childUrl =
          Uri.parse(qr.first).queryParametersAll['mulitpleURL']!.first;
      expect(
        Uri.decodeComponent(childUrl),
        contains('Google:levi@gmail.com:'),
      );
    });
  });

  group('BatchQrCodec.parseBatchShare', () {
    test('round-trip from Android comment sample shape', () {
      const child =
          'mustauth://totp/Google:levi@gmail.com?secret=HXDMVJECJJWSRB3HWIZR4IFUGFTMXBOZ'
          '&issuer=Google&algorithm=SHA1&digits=6&period=30&action=set'
          '&group=1&group=2';
      final batch =
          'mustauth://mulitpleshare/mulitpleshare?action=mulitpleshare'
          '&mulitpleURL=${Uri.encodeComponent(child)}'
          '&mulitpleURL=${Uri.encodeComponent(child)}';

      final accounts = BatchQrCodec.parseBatchShare(batch);
      expect(accounts.length, 2);
      expect(accounts.first.issuer, 'Google');
      expect(accounts.first.account, 'levi@gmail.com');
      expect(accounts.first.groupList, ['1', '2']);
    });

    test('isBatchSharePayload detects mulitpleURL typo key', () {
      expect(
        BatchQrCodec.isBatchSharePayload(
          'mustauth://mulitpleshare/mulitpleshare?mulitpleURL=x',
        ),
        isTrue,
      );
    });
  });
}
