import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_auth_qrcode_2fa/domain/otp_account.dart';
import 'package:flutter_auth_qrcode_2fa/presentation/providers.dart';
import 'package:flutter_auth_qrcode_2fa/presentation/screens/account_edit_screen.dart';
import 'package:flutter_auth_qrcode_2fa/presentation/screens/groups_screen.dart';
import 'package:flutter_auth_qrcode_2fa/presentation/screens/qr_scan_screen.dart';
import 'package:flutter_auth_qrcode_2fa/presentation/screens/settings_screen.dart';
import 'package:flutter_auth_qrcode_2fa/presentation/screens/share_select_screen.dart';
import 'package:flutter_auth_qrcode_2fa/presentation/widgets/account_tile.dart';

class AccountListScreen extends ConsumerWidget {
  const AccountListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(accountsProvider);
    final groupsAsync = ref.watch(groupsListProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('MustAuth'),
        actions: [
          IconButton(
            icon: const Icon(Icons.folder),
            tooltip: '分組',
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute<void>(builder: (_) => const GroupsScreen()),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.share),
            tooltip: '分享',
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute<void>(
                builder: (_) => const ShareSelectScreen(),
              ),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute<void>(builder: (_) => const SettingsScreen()),
            ),
          ),
        ],
      ),
      body: groupsAsync.when(
        data: (groups) {
          if (state.loading) {
            return const Center(child: CircularProgressIndicator());
          }
          if (state.error != null) {
            return Center(child: Text('載入失敗：${state.error}'));
          }
          final accounts =
              ref.read(accountsProvider.notifier).filteredAccounts(groups);
          return Column(
            children: [
              if (groups.isNotEmpty)
                SizedBox(
                  height: 48,
                  child: ListView(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    children: [
                      FilterChip(
                        label: const Text('全部'),
                        selected: state.selectedGroupId == null,
                        onSelected: (_) => ref
                            .read(accountsProvider.notifier)
                            .setGroupFilter(null),
                      ),
                      for (final g in groups)
                        Padding(
                          padding: const EdgeInsets.only(left: 4),
                          child: FilterChip(
                            label: Text(g.text),
                            selected: state.selectedGroupId == g.id,
                            onSelected: (_) => ref
                                .read(accountsProvider.notifier)
                                .setGroupFilter(g.id),
                          ),
                        ),
                    ],
                  ),
                ),
              Expanded(
                child: accounts.isEmpty
                    ? const Center(child: Text('尚無帳戶，請新增或掃描 QR'))
                    : RefreshIndicator(
                        onRefresh: () =>
                            ref.read(accountsProvider.notifier).load(),
                        child: ListView.builder(
                          itemCount: accounts.length,
                          itemBuilder: (context, i) {
                            final a = accounts[i];
                            return AccountTile(
                              account: a,
                              onPin: () => ref
                                  .read(accountsProvider.notifier)
                                  .togglePin(a),
                              onEdit: () => _edit(context, ref, a),
                              onDelete: () => _delete(context, ref, a),
                            );
                          },
                        ),
                      ),
              ),
            ],
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('分組載入失敗：$e')),
      ),
      floatingActionButton: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          FloatingActionButton.small(
            heroTag: 'scan',
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute<void>(builder: (_) => const QrScanScreen()),
            ),
            child: const Icon(Icons.qr_code_scanner),
          ),
          const SizedBox(height: 8),
          FloatingActionButton(
            heroTag: 'add',
            onPressed: () => _edit(context, ref, null),
            child: const Icon(Icons.add),
          ),
        ],
      ),
    );
  }

  Future<void> _edit(
    BuildContext context,
    WidgetRef ref,
    OtpAccount? existing,
  ) async {
    final result = await Navigator.push<OtpAccount>(
      context,
      MaterialPageRoute(
        builder: (_) => AccountEditScreen(existing: existing),
      ),
    );
    if (result == null) return;
    if (existing != null) {
      await ref.read(accountsProvider.notifier).update(result);
    } else {
      await ref.read(accountsProvider.notifier).add(result);
    }
  }

  Future<void> _delete(
    BuildContext context,
    WidgetRef ref,
    OtpAccount account,
  ) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('刪除帳戶'),
        content: Text('確定刪除 ${account.displayTitle()}？'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('取消'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('刪除'),
          ),
        ],
      ),
    );
    if (ok == true) {
      await ref.read(accountsProvider.notifier).delete(account.lastUsed);
    }
  }
}
