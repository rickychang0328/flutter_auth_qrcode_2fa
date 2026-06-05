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
          final pinned = groups.where((g) => g.pinned).toList();
          final unpinned = groups.where((g) => !g.pinned).toList();

          return SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Padding(
                  padding: EdgeInsets.fromLTRB(16, 12, 16, 4),
                  child: Text(
                    '長按右側拖曳圖示可調整順序',
                    style: TextStyle(color: Colors.grey),
                  ),
                ),
                if (pinned.isNotEmpty) ...[
                  _sectionHeader('已釘選'),
                  _reorderableSection(
                    section: pinned,
                    pinned: pinned,
                    unpinned: unpinned,
                    onReorder: (oldIndex, newIndex) =>
                        _reorderPinned(pinned, unpinned, oldIndex, newIndex),
                  ),
                ],
                if (unpinned.isNotEmpty) ...[
                  _sectionHeader('其他分組'),
                  _reorderableSection(
                    section: unpinned,
                    pinned: pinned,
                    unpinned: unpinned,
                    onReorder: (oldIndex, newIndex) =>
                        _reorderUnpinned(pinned, unpinned, oldIndex, newIndex),
                  ),
                ],
              ],
            ),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('載入分組失敗：$e')),
      ),
    );
  }

  Widget _sectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
      child: Text(
        title,
        style: Theme.of(context).textTheme.titleSmall,
      ),
    );
  }

  Widget _reorderableSection({
    required List<GroupModel> section,
    required List<GroupModel> pinned,
    required List<GroupModel> unpinned,
    required void Function(int oldIndex, int newIndex) onReorder,
  }) {
    return ReorderableListView(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      buildDefaultDragHandles: false,
      onReorder: onReorder,
      children: [
        for (var i = 0; i < section.length; i++)
          _groupTile(
            key: ValueKey(section[i].id),
            group: section[i],
            index: i,
          ),
      ],
    );
  }

  Widget _groupTile({
    required Key key,
    required GroupModel group,
    required int index,
  }) {
    return ListTile(
      key: key,
      leading: Icon(group.pinned ? Icons.push_pin : Icons.folder),
      title: Text(group.text),
      subtitle: Text('${group.codeLastIdList.length} 個帳戶'),
      onTap: () => _openEdit(context, existing: group),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          PopupMenuButton<String>(
            onSelected: (v) async {
              final repo = await ref.read(groupRepositoryProvider.future);
              if (v == 'pin') await repo.togglePin(group.id);
              if (v == 'delete') await repo.delete(group.id);
              ref.invalidate(groupsListProvider);
            },
            itemBuilder: (_) => [
              PopupMenuItem(
                value: 'pin',
                child: Text(group.pinned ? '取消釘選' : '釘選'),
              ),
              const PopupMenuItem(
                value: 'delete',
                child: Text('刪除'),
              ),
            ],
          ),
          ReorderableDragStartListener(
            index: index,
            child: const Tooltip(
              message: '拖曳排序',
              child: Padding(
                padding: EdgeInsets.only(left: 4),
                child: Icon(Icons.drag_handle),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _reorderPinned(
    List<GroupModel> pinned,
    List<GroupModel> unpinned,
    int oldIndex,
    int newIndex,
  ) async {
    final updatedPinned = List<GroupModel>.from(pinned);
    if (newIndex > oldIndex) newIndex--;
    final item = updatedPinned.removeAt(oldIndex);
    updatedPinned.insert(newIndex, item);
    await _persistOrder([...updatedPinned, ...unpinned]);
  }

  Future<void> _reorderUnpinned(
    List<GroupModel> pinned,
    List<GroupModel> unpinned,
    int oldIndex,
    int newIndex,
  ) async {
    final updatedUnpinned = List<GroupModel>.from(unpinned);
    if (newIndex > oldIndex) newIndex--;
    final item = updatedUnpinned.removeAt(oldIndex);
    updatedUnpinned.insert(newIndex, item);
    await _persistOrder([...pinned, ...updatedUnpinned]);
  }

  Future<void> _persistOrder(List<GroupModel> ordered) async {
    final repo = await ref.read(groupRepositoryProvider.future);
    await repo.reorderAll(ordered);
    ref.invalidate(groupsListProvider);
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
