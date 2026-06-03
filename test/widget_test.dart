import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_auth_qrcode_2fa/domain/batch_qr_codec.dart';
import 'package:flutter_auth_qrcode_2fa/domain/otp_account.dart';
import 'package:flutter_auth_qrcode_2fa/domain/base32_util.dart';
import 'package:flutter_auth_qrcode_2fa/domain/otp_type.dart';

void main() {
  test('batch QR roundtrip', () {
    final account = OtpAccount(
      type: OtpType.totp,
      secret: Base32Util.decode('JBSWY3DPEHPK3PXP'),
      secretText: 'JBSWY3DPEHPK3PXP',
      issuer: 'Test',
      account: 'user',
      label: 'user',
      lastUsed: 1,
    );
    final qr = BatchQrCodec.generateQrCodeStrings([account]);
    expect(qr, isNotEmpty);
    final parsed = BatchQrCodec.parseBatchShare(qr.first);
    expect(parsed.first.secretText, account.secretText);
  });
}
