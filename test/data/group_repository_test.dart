import 'package:flutter_auth_qrcode_2fa/data/app_preferences.dart';
import 'package:flutter_auth_qrcode_2fa/data/group_repository.dart';
import 'package:flutter_auth_qrcode_2fa/domain/group_model.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  late AppPreferences prefs;
  late GroupRepository repo;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    prefs = await AppPreferences.create();
    repo = GroupRepository(prefs);
  });

  test('create assigns id and persists codeLastIdList', () async {
    final g = await repo.create('工作', codeLastIdList: [100, 200]);
    expect(g.id, 1);
    expect(g.codeLastIdList, [100, 200]);

    final all = await repo.loadAll();
    expect(all, hasLength(1));
    expect(all.single.text, '工作');
    expect(all.single.codeLastIdList, [100, 200]);
  });

  test('update replaces codeLastIdList in grouplistjson', () async {
    final g = await repo.create('A');
    final updated = g.copyWith(codeLastIdList: [42]);
    await repo.update(updated);

    final all = await repo.loadAll();
    expect(all.single.codeLastIdList, [42]);
  });

  test('update throws when group id missing', () async {
    final missing = GroupModel(id: 999, text: 'x', codeLastIdList: [1]);
    expect(() => repo.update(missing), throwsA(isA<StateError>()));
  });
}
