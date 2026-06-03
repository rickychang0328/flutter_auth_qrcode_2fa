import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_auth_qrcode_2fa/presentation/providers.dart';
import 'package:flutter_auth_qrcode_2fa/presentation/screens/unlock_screen.dart';

/// 分享前安全驗證閘道 (T5.6 / T6.1).
Future<bool> runSecurityGate(BuildContext context, WidgetRef ref) async {
  final security = await ref.read(securityServiceProvider.future);
  if (!security.isSecurityEnabled &&
      (security.gesturePattern == null ||
          security.gesturePattern!.isEmpty)) {
    return true;
  }

  var unlocked = false;
  if (!context.mounted) return false;
  await Navigator.push<void>(
    context,
    MaterialPageRoute(
      builder: (ctx) => UnlockScreen(
        onUnlocked: () {
          unlocked = true;
          Navigator.pop(ctx);
        },
      ),
    ),
  );
  return unlocked;
}
