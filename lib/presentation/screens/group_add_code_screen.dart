import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_auth_qrcode_2fa/presentation/providers.dart';

/// Mirrors Android `GroupAddCodeActivity` — pick accounts to add to a group.
class GroupAddCodeScreen extends ConsumerStatefulWidget {
  const GroupAddCodeScreen({
    super.key,
    required this.currentCodeLastIdList,
  });

  final List<int> currentCodeLastIdList;

  @override
  ConsumerState<GroupAddCodeScreen> createState() => _GroupAddCodeScreenState();
}

class _GroupAddCodeScreenState extends ConsumerState<GroupAddCodeScreen> {
  final Set<int> _selected = {};
  String _query = '';

  @override
  Widget build(BuildContext context) {
    final accountsState = ref.watch(accountsProvider);
    final inGroup = widget.currentCodeLastIdList.toSet();
    var candidates = accountsState.accounts
        .where((a) => !inGroup.contains(a.lastUsed))
        .toList();
    if (_query.isNotEmpty) {
      final q = _query.toLowerCase();
      candidates = candidates
          .where(
            (a) =>
                a.issuer.toLowerCase().contains(q) ||
                a.account.toLowerCase().contains(q),
          )
          .toList();
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('新增驗證碼'),
        actions: [
          TextButton(
            onPressed: _selected.isEmpty ? null : _confirm,
            child: const Text('加入'),
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12),
            child: TextField(
              decoration: const InputDecoration(
                hintText: '搜尋發行者或帳戶',
                prefixIcon: Icon(Icons.search),
                border: OutlineInputBorder(),
              ),
              onChanged: (v) => setState(() => _query = v.trim()),
            ),
          ),
          Expanded(
            child: accountsState.loading
                ? const Center(child: CircularProgressIndicator())
                : candidates.isEmpty
                    ? Center(
                        child: Text(
                          accountsState.accounts.isEmpty
                              ? '尚無可加入的驗證碼'
                              : '此分組已包含全部驗證碼',
                        ),
                      )
                    : ListView.builder(
                        itemCount: candidates.length,
                        itemBuilder: (context, i) {
                          final a = candidates[i];
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
                            subtitle: Text(a.account),
                            secondary: Text(
                              a.currentOtp ?? '',
                              style: Theme.of(context).textTheme.titleMedium,
                            ),
                          );
                        },
                      ),
          ),
        ],
      ),
    );
  }

  void _confirm() {
    final merged = [
      ...widget.currentCodeLastIdList,
      ..._selected,
    ];
    Navigator.pop(context, merged);
  }
}
