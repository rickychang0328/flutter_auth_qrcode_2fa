import 'package:flutter_auth_qrcode_2fa/domain/base32_util.dart';
import 'package:flutter_auth_qrcode_2fa/domain/otp_account.dart';
import 'package:flutter_auth_qrcode_2fa/domain/otp_type.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('OtpAccount toJson uses Android field names', () {
    final account = OtpAccount(
      type: OtpType.totp,
      secret: Base32Util.decode('JBSWY3DPEHPK3PXP'),
      secretText: 'JBSWY3DPEHPK3PXP',
      issuer: 'GitHub',
      account: 'user',
      label: 'GitHub:user',
      lastUsed: 99,
      isTop: true,
    );
    final json = account.toJson();
    expect(json['secret'], 'JBSWY3DPEHPK3PXP');
    expect(json['last_used'], 99);
    expect(json['istag'], true);
    expect(json['type'], 'TOTP');

    final restored = OtpAccount.fromJson(json);
    expect(restored.issuer, 'GitHub');
    expect(restored.isTop, true);
  });
}
