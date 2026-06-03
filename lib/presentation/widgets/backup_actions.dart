import 'dart:convert';
import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_auth_qrcode_2fa/data/backup_service.dart';
import 'package:flutter_auth_qrcode_2fa/domain/otp_account.dart';
import 'package:flutter_auth_qrcode_2fa/presentation/providers.dart';
import 'package:flutter_auth_qrcode_2fa/presentation/widgets/duplicate_account_dialog.dart';

final backupServiceProvider = Provider<BackupService>((ref) => BackupService());

Future<void> exportPlainBackup(BuildContext context, WidgetRef ref) async {
  final accounts = ref.read(accountsProvider).accounts;
  if (accounts.isEmpty) {
    _snack(context, '沒有可匯出的帳戶');
    return;
  }
  final service = ref.read(backupServiceProvider);
  final json = service.exportPlainJson(accounts);
  final path = await FilePicker.platform.saveFile(
    dialogTitle: '匯出明文備份',
    fileName: BackupService.plainFileName,
    type: FileType.custom,
    allowedExtensions: ['json'],
    bytes: Uint8List.fromList(utf8.encode(json)),
  );
  if (!context.mounted) return;
  if (path != null) {
    _snack(context, '已匯出明文備份');
  }
}

Future<void> exportEncryptedBackup(BuildContext context, WidgetRef ref) async {
  final accounts = ref.read(accountsProvider).accounts;
  if (accounts.isEmpty) {
    _snack(context, '沒有可匯出的帳戶');
    return;
  }
  final password = await _askPassword(context, title: '設定備份密碼');
  if (password == null || !context.mounted) return;

  try {
    final service = ref.read(backupServiceProvider);
    final bytes = await service.exportEncrypted(accounts, password);
    final path = await FilePicker.platform.saveFile(
      dialogTitle: '匯出加密備份',
      fileName: BackupService.encryptedFileName,
      type: FileType.custom,
      allowedExtensions: ['aes'],
      bytes: bytes,
    );
    if (!context.mounted) return;
    if (path != null) {
      _snack(context, '已匯出加密備份 (.json.aes)');
    }
  } catch (e) {
    if (context.mounted) {
      _snack(context, '匯出失敗：$e');
    }
  }
}

Future<void> importPlainBackup(BuildContext context, WidgetRef ref) async {
  final result = await FilePicker.platform.pickFiles(
    type: FileType.custom,
    allowedExtensions: ['json'],
    withData: true,
  );
  if (result == null || result.files.isEmpty || !context.mounted) return;
  final file = result.files.single;
  final bytes = file.bytes;
  if (bytes == null) {
    _snack(context, '無法讀取檔案');
    return;
  }
  try {
    final service = ref.read(backupServiceProvider);
    final imported = service.parsePlainBytes(bytes);
    if (!context.mounted) return;
    await _finishImport(context, ref, imported);
  } catch (e) {
    if (context.mounted) _snack(context, '匯入失敗：$e');
  }
}

Future<void> importEncryptedBackup(BuildContext context, WidgetRef ref) async {
  final result = await FilePicker.platform.pickFiles(
    type: FileType.custom,
    allowedExtensions: ['aes'],
    withData: true,
  );
  if (result == null || result.files.isEmpty || !context.mounted) return;
  final bytes = result.files.single.bytes;
  if (bytes == null) {
    _snack(context, '無法讀取檔案');
    return;
  }
  final password = await _askPassword(context, title: '輸入備份密碼');
  if (password == null || !context.mounted) return;

  try {
    final service = ref.read(backupServiceProvider);
    final imported = await service.importEncrypted(bytes, password);
    if (!context.mounted) return;
    await _finishImport(context, ref, imported);
  } catch (e) {
    if (context.mounted) _snack(context, '匯入失敗：$e');
  }
}

Future<void> _finishImport(
  BuildContext context,
  WidgetRef ref,
  List<OtpAccount> imported,
) async {
  if (imported.isEmpty) {
    _snack(context, '備份中沒有帳戶資料');
    return;
  }
  final mode = await showDialog<_ImportMode>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: const Text('還原備份'),
      content: Text('將還原 ${imported.length} 筆帳戶，請選擇方式：'),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(ctx, _ImportMode.merge),
          child: const Text('合併（略過重複）'),
        ),
        FilledButton(
          onPressed: () => Navigator.pop(ctx, _ImportMode.replace),
          child: const Text('取代全部'),
        ),
      ],
    ),
  );
  if (mode == null || !context.mounted) return;

  final notifier = ref.read(accountsProvider.notifier);
  if (mode == _ImportMode.replace) {
    await notifier.replaceAll(imported);
    if (context.mounted) {
      _snack(context, '已取代全部帳戶（${imported.length} 筆）');
    }
    return;
  }

  var added = 0;
  final repo = ref.read(accountRepositoryProvider);
  for (final account in imported) {
    final all = await repo.loadAll();
    final dup = repo.findDuplicate(all, account);
    if (dup != null && context.mounted) {
      final action = await showDuplicateAccountDialog(context, dup);
      if (action == DuplicateAction.cancel) continue;
      if (action == DuplicateAction.overwrite) {
        account.lastUsed = dup.lastUsed;
        await notifier.update(account);
        continue;
      }
    }
    await notifier.add(account);
    added++;
  }
  if (context.mounted) {
    _snack(context, '合併完成（新增 $added 筆）');
  }
}

enum _ImportMode { merge, replace }

Future<String?> _askPassword(
  BuildContext context, {
  required String title,
}) async {
  final controller = TextEditingController();
  return showDialog<String>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: Text(title),
      content: TextField(
        controller: controller,
        obscureText: true,
        decoration: const InputDecoration(labelText: '密碼'),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(ctx),
          child: const Text('取消'),
        ),
        FilledButton(
          onPressed: () => Navigator.pop(ctx, controller.text),
          child: const Text('確定'),
        ),
      ],
    ),
  );
}

void _snack(BuildContext context, String message) {
  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
}
