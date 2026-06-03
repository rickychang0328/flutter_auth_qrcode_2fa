import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_auth_qrcode_2fa/presentation/providers.dart';
import 'package:flutter_auth_qrcode_2fa/presentation/widgets/pattern_lock_grid.dart';

class UnlockScreen extends ConsumerWidget {
  const UnlockScreen({super.key, required this.onUnlocked});

  final VoidCallback onUnlocked;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final securityAsync = ref.watch(securityServiceProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('解鎖 MustAuth')),
      body: securityAsync.when(
        data: (security) {
          final hasGesture = security.gesturePattern != null &&
              security.gesturePattern!.isNotEmpty;
          return ListView(
            padding: const EdgeInsets.all(24),
            children: [
              if (security.isSecurityEnabled) ...[
                FilledButton.icon(
                  onPressed: () async {
                    final ok = await security.authenticateWithBiometrics();
                    if (ok) {
                      await security.onUnlockSuccess();
                      onUnlocked();
                    }
                  },
                  icon: const Icon(Icons.fingerprint),
                  label: const Text('指紋 / 臉部辨識'),
                ),
                const SizedBox(height: 24),
              ],
              if (hasGesture) ...[
                const Text('或繪製手勢密碼'),
                PatternLockGrid(
                  verifyPattern: security.gesturePattern,
                  onPatternComplete: (pattern) async {
                    if (security.verifyGesture(pattern)) {
                      await security.onUnlockSuccess();
                      onUnlocked();
                    }
                  },
                ),
              ] else
                const Text('尚未設定手勢，請使用生物辨識或至設定頁設定。'),
            ],
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('載入失敗：$e')),
      ),
    );
  }
}
