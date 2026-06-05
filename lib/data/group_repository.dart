import 'dart:convert';

import 'package:flutter_auth_qrcode_2fa/data/app_preferences.dart';
import 'package:flutter_auth_qrcode_2fa/domain/group_model.dart';

class GroupRepository {
  GroupRepository(this._prefs);

  static const int maxGroups = 10;

  final AppPreferences _prefs;

  Future<List<GroupModel>> loadAll() async {
    final raw = _prefs.grouplistJsonRaw;
    if (raw == null || raw.isEmpty) return [];
    final list = jsonDecode(raw) as List<dynamic>;
    return list
        .map((e) => GroupModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<void> saveAll(List<GroupModel> groups) async {
    final encoded = jsonEncode(groups.map((g) => g.toJson()).toList());
    await _prefs.setGrouplistJson(encoded);
  }

  Future<GroupModel> create(
    String text, {
    List<int>? codeLastIdList,
  }) async {
    final all = await loadAll();
    if (all.length >= maxGroups) {
      throw StateError('最多只能建立 $maxGroups 個分組');
    }
    final nextId = all.isEmpty
        ? 1
        : all.map((g) => g.id).reduce((a, b) => a > b ? a : b) + 1;
    final group = GroupModel(
      id: nextId,
      text: text,
      codeLastIdList: codeLastIdList,
    );
    all.add(group);
    await saveAll(all);
    return group;
  }

  Future<void> update(GroupModel group) async {
    final all = await loadAll();
    final idx = all.indexWhere((g) => g.id == group.id);
    if (idx < 0) {
      throw StateError('找不到分組，請重新整理後再試');
    }
    all[idx] = group;
    await saveAll(all);
  }

  Future<void> delete(int id) async {
    final all = await loadAll();
    all.removeWhere((g) => g.id == id);
    await saveAll(all);
  }

  Future<void> togglePin(int id) async {
    final all = await loadAll();
    final idx = all.indexWhere((g) => g.id == id);
    if (idx >= 0) {
      all[idx].pinned = !all[idx].pinned;
      await saveAll(all);
    }
  }

  /// Persists [groups] in list order (used after drag reorder).
  Future<void> reorderAll(List<GroupModel> groups) => saveAll(groups);

  /// Appends [lastUsed] to each group's [GroupModel.codeLastIdList] (no-op if
  /// already present).
  Future<void> addLastUsedToGroups(Iterable<int> groupIds, int lastUsed) async {
    final idSet = groupIds.toSet();
    if (idSet.isEmpty) return;

    final all = await loadAll();
    var changed = false;
    for (var i = 0; i < all.length; i++) {
      if (!idSet.contains(all[i].id)) continue;
      if (all[i].codeLastIdList.contains(lastUsed)) continue;
      all[i] = all[i].copyWith(
        codeLastIdList: [...all[i].codeLastIdList, lastUsed],
      );
      changed = true;
    }
    if (changed) await saveAll(all);
  }
}
