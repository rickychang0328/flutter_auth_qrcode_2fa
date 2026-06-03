import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_auth_qrcode_2fa/domain/otp_account.dart';
import 'package:flutter_auth_qrcode_2fa/domain/otp_generator.dart';

class AccountTile extends StatefulWidget {
  const AccountTile({
    super.key,
    required this.account,
    required this.onPin,
    required this.onEdit,
    required this.onDelete,
  });

  final OtpAccount account;
  final VoidCallback onPin;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  State<AccountTile> createState() => _AccountTileState();
}

class _AccountTileState extends State<AccountTile> {
  Timer? _timer;
  int _remaining = OtpGenerator.totpDefaultPeriod;

  @override
  void initState() {
    super.initState();
    _tick();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) => _tick());
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _tick() {
    if (!widget.account.isTimeBased) return;
    final now = DateTime.now().millisecondsSinceEpoch ~/ 1000;
    final period = widget.account.period;
    final elapsed = now % period;
    setState(() {
      _remaining = period - elapsed;
      widget.account.remainingTime = _remaining;
      widget.account.recomputeOtp(timeSeconds: now);
    });
  }

  @override
  Widget build(BuildContext context) {
    final a = widget.account;
    final code = a.hideOtp ? '••••••' : (a.currentOtp ?? '------');

    return Card(
      child: ListTile(
        leading: Icon(
          a.isTop ? Icons.push_pin : Icons.vpn_key,
          color: a.isTop ? Theme.of(context).colorScheme.primary : null,
        ),
        title: Text(a.displayTitle()),
        subtitle: widget.account.isTimeBased
            ? Text('剩餘 $_remaining 秒')
            : Text('HOTP 計數器：${a.counter}'),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              code,
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    letterSpacing: 2,
                    fontFeatures: const [FontFeature.tabularFigures()],
                  ),
            ),
            IconButton(
              icon: const Icon(Icons.copy),
              tooltip: '複製',
              onPressed: a.hideOtp
                  ? null
                  : () async {
                      final otp = a.currentOtp ?? '';
                      await Clipboard.setData(ClipboardData(text: otp));
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('已複製驗證碼')),
                        );
                      }
                    },
            ),
          ],
        ),
        onTap: widget.onEdit,
        onLongPress: () {
          showModalBottomSheet<void>(
            context: context,
            builder: (ctx) => SafeArea(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  ListTile(
                    leading: const Icon(Icons.push_pin),
                    title: Text(a.isTop ? '取消置頂' : '置頂'),
                    onTap: () {
                      Navigator.pop(ctx);
                      widget.onPin();
                    },
                  ),
                  ListTile(
                    leading: const Icon(Icons.edit),
                    title: const Text('編輯'),
                    onTap: () {
                      Navigator.pop(ctx);
                      widget.onEdit();
                    },
                  ),
                  ListTile(
                    leading: const Icon(Icons.delete),
                    title: const Text('刪除'),
                    onTap: () {
                      Navigator.pop(ctx);
                      widget.onDelete();
                    },
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
