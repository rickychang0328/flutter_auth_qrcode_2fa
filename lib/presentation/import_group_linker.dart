import 'package:flutter_auth_qrcode_2fa/domain/group_model.dart';

/// Resolves which [GroupModel.id] values should receive a new account's
/// [lastUsed] after import, matching Android scanner behavior.
List<int> resolveImportGroupLinkTargets({
  required int? selectedGroupId,
  required List<String> uriGroupNames,
  required List<GroupModel> groups,
}) {
  final ids = <int>{};

  if (selectedGroupId != null) {
    if (groups.any((g) => g.id == selectedGroupId)) {
      ids.add(selectedGroupId);
    }
    final names = uriGroupNames.toSet();
    for (final g in groups) {
      if (names.contains(g.text)) {
        ids.add(g.id);
      }
    }
  } else {
    final names = uriGroupNames.toSet();
    for (final g in groups) {
      if (names.contains(g.text)) {
        ids.add(g.id);
      }
    }
  }

  return ids.toList();
}
