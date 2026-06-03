import 'package:flutter/material.dart';
import 'package:flutter_auth_qrcode_2fa/domain/otp_account.dart';

enum DuplicateAction { overwrite, cancel }

Future<DuplicateAction?> showDuplicateAccountDialog(
  BuildContext context,
  OtpAccount existing,
) {
  return showDialog<DuplicateAction>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: const Text('重複帳戶'),
      content: Text(
        '已存在相同帳戶：${existing.displayTitle()}\n是否要覆蓋？',
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(ctx, DuplicateAction.cancel),
          child: const Text('取消'),
        ),
        FilledButton(
          onPressed: () => Navigator.pop(ctx, DuplicateAction.overwrite),
          child: const Text('覆蓋'),
        ),
      ],
    ),
  );
}
