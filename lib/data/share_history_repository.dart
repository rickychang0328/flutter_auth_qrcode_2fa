import 'dart:convert';

import 'package:flutter_auth_qrcode_2fa/data/app_preferences.dart';
import 'package:flutter_auth_qrcode_2fa/domain/otp_account.dart';
import 'package:flutter_auth_qrcode_2fa/domain/share_account.dart';
import 'package:intl/intl.dart';

class ShareHistoryRepository {
  ShareHistoryRepository(this._prefs);

  final AppPreferences _prefs;

  Future<List<ShareAccount>> loadAll() async {
    final raw = _prefs.shareAccountListJsonRaw;
    if (raw == null || raw.isEmpty) return [];
    final list = jsonDecode(raw) as List<dynamic>;
    return list
        .map((e) => ShareAccount.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<void> _saveAll(List<ShareAccount> items) async {
    final encoded = jsonEncode(items.map((e) => e.toJson()).toList());
    await _prefs.setShareAccountListJson(encoded);
  }

  Future<void> recordExport(List<OtpAccount> accounts) async {
    final all = await loadAll();
    all.insert(
      0,
      ShareAccount(
        type: 'export',
        actionContent: '匯出：${accounts.length}個驗證碼',
        actionDate: DateFormat('yyyy-MM-dd HH:mm:ss').format(DateTime.now()),
        shareAccountDetail: accounts
            .map(
              (a) => ShareAccountDetail(
                issuer: a.issuer,
                account: a.account,
                group: a.groupList.join(' '),
              ),
            )
            .toList(),
      ),
    );
    await _saveAll(all);
  }

  Future<void> recordImport(List<OtpAccount> accounts) async {
    final all = await loadAll();
    all.insert(
      0,
      ShareAccount(
        type: 'import',
        actionContent: '匯入：${accounts.length}個驗證碼',
        actionDate: DateFormat('yyyy-MM-dd HH:mm:ss').format(DateTime.now()),
        shareAccountDetail: accounts
            .map(
              (a) => ShareAccountDetail(
                issuer: a.issuer,
                account: a.account,
                group: a.groupList.join(' '),
              ),
            )
            .toList(),
      ),
    );
    await _saveAll(all);
  }
}
