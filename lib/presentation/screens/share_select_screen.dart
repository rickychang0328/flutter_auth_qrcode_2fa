import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_auth_qrcode_2fa/presentation/providers.dart';
import 'package:flutter_auth_qrcode_2fa/presentation/screens/share_history_screen.dart';
import 'package:flutter_auth_qrcode_2fa/presentation/screens/share_qr_screen.dart';
import 'package:flutter_auth_qrcode_2fa/presentation/security_gate.dart';

class ShareSelectScreen extends ConsumerStatefulWidget {
  const ShareSelectScreen({super.key});

  @override
  ConsumerState<ShareSelectScreen> createState() => _ShareSelectScreenState();
}

class _ShareSelectScreenState extends ConsumerState<ShareSelectScreen> {
  final Set<int> _selected = {};

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(accountsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('選擇匯出帳戶'),
        actions: [
          IconButton(
            icon: const Icon(Icons.history),
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute<void>(
                builder: (_) => const ShareHistoryScreen(),
              ),
            ),
          ),
          TextButton(
            onPressed: _selected.isEmpty ? null : () => _export(context),
            child: const Text('匯出 QR'),
          ),
        ],
      ),
      body: state.loading
          ? const Center(child: CircularProgressIndicator())
          : ListView.builder(
              itemCount: state.accounts.length,
              itemBuilder: (context, i) {
                final a = state.accounts[i];
                final checked = _selected.contains(a.lastUsed);
                return CheckboxListTile(
                  value: checked,
                  onChanged: (v) {
                    setState(() {
                      if (v == true) {
                        _selected.add(a.lastUsed);
                      } else {
                        _selected.remove(a.lastUsed);
                      }
                    });
                  },
                  title: Text(a.displayTitle()),
                );
              },
            ),
    );
  }

  Future<void> _export(BuildContext context) async {
    final ok = await runSecurityGate(context, ref);
    if (!ok || !context.mounted) return;

    final accounts = ref
        .read(accountsProvider)
        .accounts
        .where((a) => _selected.contains(a.lastUsed))
        .toList();
    final groups = await ref.read(groupsListProvider.future);

    if (!context.mounted) return;
    await Navigator.push(
      context,
      MaterialPageRoute<void>(
        builder: (_) => ShareQrScreen(
          accounts: accounts,
          groups: groups,
        ),
      ),
    );
  }
}
