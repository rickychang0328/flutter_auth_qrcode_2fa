import 'dart:convert';
import 'dart:io';

import 'package:cryptography/cryptography.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_auth_qrcode_2fa/data/aes_gcm_cipher.dart';
import 'package:flutter_auth_qrcode_2fa/domain/otp_account.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:path_provider/path_provider.dart';

/// Encrypted `secrets.dat` — mirrors Android `DatabaseHelper`.
class EncryptedAccountStore {
  EncryptedAccountStore({
    FlutterSecureStorage? secureStorage,
    File? testFile,
  })  : _secureStorage = secureStorage ?? const FlutterSecureStorage(),
        _testFile = testFile;

  static const String fileName = 'secrets.dat';
  static const String keyStorageName = 'otp_aes_key';

  final FlutterSecureStorage _secureStorage;
  final File? _testFile;
  SecretKey? _cachedKey;

  Future<File> _dbFile() async {
    final testFile = _testFile;
    if (testFile != null) return testFile;
    final dir = await getApplicationDocumentsDirectory();
    return File('${dir.path}/$fileName');
  }

  Future<SecretKey> _loadOrCreateKey() async {
    if (_cachedKey != null) return _cachedKey!;
    final stored = await _secureStorage.read(key: keyStorageName);
    if (stored != null && stored.isNotEmpty) {
      final bytes = base64Decode(stored);
      _cachedKey = await AesGcmCipher.keyFromBytes(bytes);
      return _cachedKey!;
    }
    final raw = AesGcmCipher.randomKeyBytes();
    await _secureStorage.write(
      key: keyStorageName,
      value: base64Encode(raw),
    );
    _cachedKey = await AesGcmCipher.keyFromBytes(raw);
    return _cachedKey!;
  }

  Future<List<OtpAccount>> loadAll() async {
    final file = await _dbFile();
    if (!await file.exists()) return [];
    final key = await _loadOrCreateKey();
    final combined = await file.readAsBytes();
    final plain = await AesGcmCipher.decrypt(key, Uint8List.fromList(combined));
    final jsonStr = utf8.decode(plain);
    if (jsonStr.trim().isEmpty) return [];
    return OtpAccount.listFromJsonString(jsonStr);
  }

  Future<void> saveAll(List<OtpAccount> accounts) async {
    final key = await _loadOrCreateKey();
    final jsonStr = OtpAccount.listToJsonString(accounts);
    final encrypted = await AesGcmCipher.encrypt(
      key,
      Uint8List.fromList(utf8.encode(jsonStr)),
    );
    final file = await _dbFile();
    await file.writeAsBytes(encrypted, flush: true);
  }

  Future<void> add(OtpAccount account) async {
    final all = await loadAll();
    account.lastUsed = DateTime.now().microsecondsSinceEpoch;
    all.add(account);
    await saveAll(all);
  }

  Future<void> update(OtpAccount account) async {
    final all = await loadAll();
    final idx = all.indexWhere((e) => e.lastUsed == account.lastUsed);
    if (idx >= 0) {
      all[idx] = account;
      await saveAll(all);
    }
  }

  Future<void> delete(int lastUsed) async {
    final all = await loadAll();
    all.removeWhere((e) => e.lastUsed == lastUsed);
    await saveAll(all);
  }

  Future<void> wipe() async {
    final file = await _dbFile();
    if (await file.exists()) await file.delete();
    await _secureStorage.delete(key: keyStorageName);
    _cachedKey = null;
  }

  @visibleForTesting
  Future<void> replaceKeyForTest(List<int> keyBytes) async {
    await _secureStorage.write(
      key: keyStorageName,
      value: base64Encode(keyBytes),
    );
    _cachedKey = await AesGcmCipher.keyFromBytes(keyBytes);
  }
}
