import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_auth_qrcode_2fa/domain/group_model.dart';
import 'package:flutter_auth_qrcode_2fa/domain/otp_account.dart';
import 'package:flutter_auth_qrcode_2fa/presentation/providers.dart';
import 'package:flutter_auth_qrcode_2fa/presentation/screens/group_add_code_screen.dart';

/// Mirrors Android `GroupEditCreateActivity` (create + edit).
class GroupEditScreen extends ConsumerStatefulWidget {
  const GroupEditScreen({super.key, this.existing});

  final GroupModel? existing;

  bool get isCreate => existing == null;

  @override
  ConsumerState<GroupEditScreen> createState() => _GroupEditScreenState();
}

class _GroupEditScreenState extends ConsumerState<GroupEditScreen> {
  late final TextEditingController _nameController;
  late GroupModel _draft;

  static final RegExp _invalidNameChars = RegExp(r'[#%&=|/?#%&？]');

  @override
  void initState() {
    super.initState();
    final existing = widget.existing;
    _draft = existing != null
        ? existing.copyWith()
        : GroupModel(id: 0, text: '');
    _nameController = TextEditingController(text: _draft.text);
    _nameController.addListener(_onNameChanged);
  }

  @override
  void dispose() {
    _nameController.removeListener(_onNameChanged);
    _nameController.dispose();
    super.dispose();
  }

  void _onNameChanged() {
    setState(() {
      _draft = _draft.copyWith(text: _nameController.text.trim());
    });
  }

  bool get _nameValid {
    final name = _draft.text;
    if (name.isEmpty || name.length > 10) return false;
    if (name.contains('\n') || name.contains(' ')) return false;
    return !_invalidNameChars.hasMatch(name);
  }

  bool get _canSave =>
      _nameValid && _draft.codeLastIdList.isNotEmpty;

  List<OtpAccount> _accountsInGroup(List<OtpAccount> all) {
    final ids = _draft.codeLastIdList.toSet();
    return all.where((a) => ids.contains(a.lastUsed)).toList();
  }

  Future<void> _openAddCode() async {
    final merged = await Navigator.push<List<int>>(
      context,
      MaterialPageRoute(
        builder: (_) => GroupAddCodeScreen(
          currentCodeLastIdList: List<int>.from(_draft.codeLastIdList),
        ),
      ),
    );
    if (merged == null || !mounted) return;
    setState(() {
      _draft = _draft.copyWith(codeLastIdList: merged);
    });
  }

  void _removeFromGroup(int lastUsed) {
    setState(() {
      _draft = _draft.copyWith(
        codeLastIdList:
            _draft.codeLastIdList.where((id) => id != lastUsed).toList(),
      );
    });
  }

  Future<void> _save() async {
    if (!_canSave) {
      _showError(_saveHint());
      return;
    }
    try {
      final repo = await ref.read(groupRepositoryProvider.future);
      if (widget.isCreate) {
        await repo.create(
          _draft.text,
          codeLastIdList: _draft.codeLastIdList,
        );
      } else {
        await repo.update(_draft);
      }
      ref.invalidate(groupsListProvider);
      if (mounted) Navigator.pop(context, true);
    } on StateError catch (e) {
      _showError(e.message);
    } catch (e) {
      _showError('儲存分組失敗：$e');
    }
  }

  String _saveHint() {
    if (!_nameValid) {
      return '分組名稱不可為空，長度 1–10 字，且不可含空白或 # % & = | / ? 等字元';
    }
    if (_draft.codeLastIdList.isEmpty) {
      return '請至少加入一個驗證碼到分組';
    }
    return '無法儲存分組';
  }

  void _showError(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final accountsState = ref.watch(accountsProvider);
    final inGroup = _accountsInGroup(accountsState.accounts);
    final title = widget.isCreate ? '建立分組' : '編輯分組';

    return Scaffold(
      appBar: AppBar(
        title: Text(title),
        actions: [
          TextButton(
            onPressed: _canSave ? _save : null,
            child: Text(widget.isCreate ? '建立' : '儲存'),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          TextField(
            controller: _nameController,
            decoration: const InputDecoration(
              labelText: '分組名稱',
              hintText: '最多 10 字',
              border: OutlineInputBorder(),
            ),
            maxLength: 10,
          ),
          const SizedBox(height: 8),
          ListTile(
            leading: const Icon(Icons.add_circle_outline),
            title: const Text('新增驗證碼'),
            subtitle: Text('已選 ${_draft.codeLastIdList.length} 個'),
            onTap: accountsState.accounts.isEmpty
                ? () => _showError('尚無驗證碼可加入，請先新增帳戶')
                : _openAddCode,
          ),
          const Divider(),
          if (inGroup.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 24),
              child: Center(child: Text('尚未加入驗證碼')),
            )
          else
            ...inGroup.map(
              (a) => ListTile(
                title: Text(a.displayTitle()),
                subtitle: Text(a.account),
                trailing: IconButton(
                  icon: const Icon(Icons.remove_circle_outline),
                  tooltip: '移出分組',
                  onPressed: () => _removeFromGroup(a.lastUsed),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
