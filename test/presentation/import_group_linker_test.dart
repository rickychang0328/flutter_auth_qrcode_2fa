import 'package:flutter_auth_qrcode_2fa/data/app_preferences.dart';
import 'package:flutter_auth_qrcode_2fa/data/group_repository.dart';
import 'package:flutter_auth_qrcode_2fa/domain/group_model.dart';
import 'package:flutter_auth_qrcode_2fa/presentation/import_group_linker.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  group('resolveImportGroupLinkTargets', () {
    final groups = [
      GroupModel(id: 1, text: 'aa'),
      GroupModel(id: 2, text: 'bb'),
    ];

    test('selected group only when filter active and no URI groups', () {
      expect(
        resolveImportGroupLinkTargets(
          selectedGroupId: 1,
          uriGroupNames: const [],
          groups: groups,
        ),
        [1],
      );
    });

    test('merges selected group with URI group names', () {
      expect(
        resolveImportGroupLinkTargets(
          selectedGroupId: 1,
          uriGroupNames: const ['bb'],
          groups: groups,
        ),
        unorderedEquals([1, 2]),
      );
    });

    test('all filter uses URI group names only', () {
      expect(
        resolveImportGroupLinkTargets(
          selectedGroupId: null,
          uriGroupNames: const ['bb'],
          groups: groups,
        ),
        [2],
      );
    });

    test('all filter with no URI groups yields empty', () {
      expect(
        resolveImportGroupLinkTargets(
          selectedGroupId: null,
          uriGroupNames: const [],
          groups: groups,
        ),
        isEmpty,
      );
    });
  });

  group('GroupRepository.addLastUsedToGroups', () {
    late GroupRepository repo;

    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await AppPreferences.create();
      repo = GroupRepository(prefs);
    });

    test('appends lastUsed to selected group', () async {
      final g = await repo.create('aa');
      await repo.addLastUsedToGroups([g.id], 12345);

      final all = await repo.loadAll();
      expect(all.single.codeLastIdList, [12345]);
    });

    test('does not duplicate lastUsed in codeLastIdList', () async {
      final g = await repo.create('aa', codeLastIdList: [99]);
      await repo.addLastUsedToGroups([g.id], 99);
      await repo.addLastUsedToGroups([g.id], 99);

      final all = await repo.loadAll();
      expect(all.single.codeLastIdList, [99]);
    });
  });
}
