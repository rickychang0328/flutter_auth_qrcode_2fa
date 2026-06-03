import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_auth_qrcode_2fa/domain/batch_qr_codec.dart';
import 'package:flutter_auth_qrcode_2fa/domain/otp_account.dart';
import 'package:flutter_auth_qrcode_2fa/domain/third_party_action.dart';
import 'package:flutter_auth_qrcode_2fa/presentation/providers.dart';
import 'package:flutter_auth_qrcode_2fa/presentation/widgets/duplicate_account_dialog.dart';

class DeepLinkHandler {
  DeepLinkHandler(this._ref);

  final Ref _ref;

  Future<void> handleUri(BuildContext context, String uri) async {
    if (BatchQrCodec.isBatchSharePayload(uri)) {
      final accounts = BatchQrCodec.parseBatchShare(uri);
      await _importBatch(context, accounts);
      return;
    }

    try {
      final account = OtpAccount.fromUri(uri);
      await _handleAccount(context, account);
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('無法解析連結：$e')),
        );
      }
    }
  }

  Future<void> _handleAccount(BuildContext context, OtpAccount account) async {
    if (account.action == ThirdPartyAction.copy) {
      account.recomputeOtp();
      final code = account.currentOtp ?? '';
      await Clipboard.setData(ClipboardData(text: code));
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('已複製驗證碼：$code')),
        );
      }
      return;
    }

    final repo = _ref.read(accountRepositoryProvider);
    final all = await repo.loadAll();
    final dup = repo.findDuplicate(all, account);
    if (dup != null && context.mounted) {
      final action = await showDuplicateAccountDialog(context, dup);
      if (action == DuplicateAction.cancel || !context.mounted) return;
      if (action == DuplicateAction.overwrite) {
        account.lastUsed = dup.lastUsed;
        await _ref.read(accountsProvider.notifier).update(account);
      }
      return;
    }

    await _ref.read(accountsProvider.notifier).add(account);
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('已新增帳戶')),
      );
    }
  }

  Future<void> _importBatch(
    BuildContext context,
    List<OtpAccount> accounts,
  ) async {
    final repo = _ref.read(accountRepositoryProvider);
    var added = 0;
    for (final account in accounts) {
      final all = await repo.loadAll();
      if (repo.findDuplicate(all, account) == null) {
        await _ref.read(accountsProvider.notifier).add(account);
        added++;
      }
    }
    final history = await _ref.read(shareHistoryProvider.future);
    await history.recordImport(accounts);
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('批次匯入完成（新增 $added 筆）')),
      );
    }
  }
}
