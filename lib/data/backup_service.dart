import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter_auth_qrcode_2fa/data/backup_crypto.dart';
import 'package:flutter_auth_qrcode_2fa/domain/otp_account.dart';

/// Plain + encrypted account backup — mirrors Android `otp_accounts.json` / `.json.aes`.
class BackupService {
  static const String plainFileName = 'otp_accounts.json';
  static const String encryptedFileName = 'otp_accounts.json.aes';

  String exportPlainJson(List<OtpAccount> accounts) =>
      OtpAccount.listToJsonString(accounts);

  List<OtpAccount> parsePlainJson(String raw) {
    final trimmed = raw.trim();
    if (trimmed.isEmpty) {
      throw const FormatException('備份檔案為空');
    }
    return OtpAccount.listFromJsonString(trimmed);
  }

  List<OtpAccount> parsePlainBytes(Uint8List bytes) =>
      parsePlainJson(utf8.decode(bytes));

  Future<Uint8List> exportEncrypted(
    List<OtpAccount> accounts,
    String password,
  ) async {
    if (password.isEmpty) {
      throw ArgumentError('請輸入備份密碼');
    }
    final json = exportPlainJson(accounts);
    return BackupCrypto.encryptJson(json, password);
  }

  Future<List<OtpAccount>> importEncrypted(
    Uint8List fileBytes,
    String password,
  ) async {
    if (password.isEmpty) {
      throw ArgumentError('請輸入備份密碼');
    }
    final json = await BackupCrypto.decryptToJson(fileBytes, password);
    return parsePlainJson(json);
  }
}
