import 'dart:io';

import 'package:flutter_auth_qrcode_2fa/data/encrypted_account_store.dart';
import 'package:flutter_auth_qrcode_2fa/domain/otp_account.dart';
import 'package:flutter_auth_qrcode_2fa/domain/otp_type.dart';
import 'package:flutter_auth_qrcode_2fa/domain/base32_util.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';

class _MemorySecureStorage extends FlutterSecureStorage {
  final Map<String, String> _data = {};

  @override
  Future<String?> read({
    required String key,
    IOSOptions? iOptions,
    AndroidOptions? aOptions,
    LinuxOptions? lOptions,
    WebOptions? webOptions,
    MacOsOptions? mOptions,
    WindowsOptions? wOptions,
  }) async =>
      _data[key];

  @override
  Future<void> write({
    required String key,
    required String? value,
    IOSOptions? iOptions,
    AndroidOptions? aOptions,
    LinuxOptions? lOptions,
    WebOptions? webOptions,
    MacOsOptions? mOptions,
    WindowsOptions? wOptions,
  }) async {
    if (value == null) {
      _data.remove(key);
    } else {
      _data[key] = value;
    }
  }

  @override
  Future<void> delete({
    required String key,
    IOSOptions? iOptions,
    AndroidOptions? aOptions,
    LinuxOptions? lOptions,
    WebOptions? webOptions,
    MacOsOptions? mOptions,
    WindowsOptions? wOptions,
  }) async {
    _data.remove(key);
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('EncryptedAccountStore CRUD roundtrip', () async {
    final tempFile = File(
      '${Directory.systemTemp.path}/mustauth_test_${DateTime.now().microsecondsSinceEpoch}.dat',
    );
    final store = EncryptedAccountStore(
      secureStorage: _MemorySecureStorage(),
      testFile: tempFile,
    );
    final secret = Base32Util.decode('JBSWY3DPEHPK3PXP');
    final account = OtpAccount(
      type: OtpType.totp,
      secret: secret,
      secretText: 'JBSWY3DPEHPK3PXP',
      issuer: 'Test',
      account: 'user',
      label: 'Test:user',
      lastUsed: 12345,
    );

    await store.add(account);
    var all = await store.loadAll();
    expect(all.length, 1);
    expect(all.first.issuer, 'Test');

    all.first.issuer = 'Updated';
    await store.update(all.first);
    all = await store.loadAll();
    expect(all.first.issuer, 'Updated');

    await store.delete(all.first.lastUsed);
    all = await store.loadAll();
    expect(all, isEmpty);
    if (await tempFile.exists()) await tempFile.delete();
  });
}
