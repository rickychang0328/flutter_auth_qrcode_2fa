import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_auth_qrcode_2fa/data/group_repository.dart';
import 'package:flutter_auth_qrcode_2fa/domain/group_model.dart';
import 'package:flutter_auth_qrcode_2fa/presentation/providers.dart';
import 'package:flutter_auth_qrcode_2fa/presentation/screens/group_edit_screen.dart';

class GroupsScreen extends ConsumerStatefulWidget {
  const GroupsScreen({super.key});

  @override
  ConsumerState<GroupsScreen> createState() => _GroupsScreenState();
}

class _GroupsScreenState extends ConsumerState<GroupsScreen> {
  @override
  Widget build(BuildContext context) {
    final groupsAsync = ref.watch(groupsListProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('分組管理')),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _openEdit(context, existing: null),
        child: const Icon(Icons.add),
      ),
      body: groupsAsync.when(
        data: (groups) {
          if (groups.isEmpty) {
            return Center(
              child: Text('尚無分組（最多 ${GroupRepository.maxGroups} 組）'),
            );
          }
          return ListView.builder(
            itemCount: groups.length,
            itemBuilder: (context, i) {
              final g = groups[i];
              return ListTile(
                leading: Icon(
                  g.pinned ? Icons.push_pin : Icons.folder,
                ),
                title: Text(g.text),
                subtitle: Text('${g.codeLastIdList.length} 個帳戶'),
                onTap: () => _openEdit(context, existing: g),
                trailing: PopupMenuButton<String>(
                  onSelected: (v) async {
                    final repo =
                        await ref.read(groupRepositoryProvider.future);
                    if (v == 'pin') await repo.togglePin(g.id);
                    if (v == 'delete') await repo.delete(g.id);
                    ref.invalidate(groupsListProvider);
                  },
                  itemBuilder: (_) => [
                    PopupMenuItem(
                      value: 'pin',
                      child: Text(g.pinned ? '取消釘選' : '釘選'),
                    ),
                    const PopupMenuItem(
                      value: 'delete',
                      child: Text('刪除'),
                    ),
                  ],
                ),
              );
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('載入分組失敗：$e')),
      ),
    );
  }

  Future<void> _openEdit(
    BuildContext context, {
    GroupModel? existing,
  }) async {
    final changed = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => GroupEditScreen(existing: existing),
      ),
    );
    if (changed == true) {
      ref.invalidate(groupsListProvider);
    }
  }
}
