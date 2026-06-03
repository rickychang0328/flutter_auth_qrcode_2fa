import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter_auth_qrcode_2fa/data/backup_crypto.dart';
import 'package:flutter_auth_qrcode_2fa/data/backup_service.dart';
import 'package:flutter_auth_qrcode_2fa/domain/base32_util.dart';
import 'package:flutter_auth_qrcode_2fa/domain/otp_account.dart';
import 'package:flutter_auth_qrcode_2fa/domain/otp_type.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('BackupCrypto', () {
    test('round-trip with fixed salt and iterations', () async {
      const password = 'test-backup-password';
      const iterations = 2500;
      final salt = Uint8List.fromList(List<int>.generate(12, (i) => i + 1));
      final account = OtpAccount(
        type: OtpType.totp,
        secret: Base32Util.decode('JBSWY3DPEHPK3PXP'),
        secretText: 'JBSWY3DPEHPK3PXP',
        issuer: 'Issuer',
        account: 'user@example.com',
        label: 'Issuer:user@example.com',
        lastUsed: 42,
      );
      final json = BackupService().exportPlainJson([account]);

      final encrypted = await BackupCrypto.encryptJsonWithParams(
        json: json,
        password: password,
        iterations: iterations,
        salt: salt,
      );

      expect(encrypted.length, greaterThan(BackupCrypto.headerLength));
      final header = ByteData.sublistView(encrypted, 0, 4);
      expect(header.getUint32(0, Endian.big), iterations);
      expect(encrypted.sublist(4, 16), salt);

      final decrypted = await BackupCrypto.decryptToJson(encrypted, password);
      final restored = BackupService().parsePlainJson(decrypted);
      expect(restored.length, 1);
      expect(restored.first.secretText, account.secretText);
      expect(restored.first.issuer, account.issuer);
      expect(restored.first.lastUsed, account.lastUsed);
    });

    test('random export via BackupService round-trip', () async {
      const password = 'another-password';
      final accounts = [
        OtpAccount(
          type: OtpType.hotp,
          secret: Base32Util.decode('JBSWY3DPEHPK3PXP'),
          secretText: 'JBSWY3DPEHPK3PXP',
          issuer: 'ACME',
          account: 'bob',
          label: 'ACME:bob',
          counter: 7,
          lastUsed: 99,
        ),
      ];
      final service = BackupService();
      final blob = await service.exportEncrypted(accounts, password);
      final back = await service.importEncrypted(blob, password);
      expect(back.first.counter, 7);
      expect(back.first.type, OtpType.hotp);
    });

    test('wrong password throws', () async {
      final blob = await BackupCrypto.encryptJson('[]', 'right');
      expect(
        () => BackupCrypto.decryptToJson(blob, 'wrong'),
        throwsA(isA<FormatException>()),
      );
    });
  });
}
