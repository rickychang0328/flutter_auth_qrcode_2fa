import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_auth_qrcode_2fa/data/account_repository.dart';
import 'package:flutter_auth_qrcode_2fa/data/app_preferences.dart';
import 'package:flutter_auth_qrcode_2fa/data/encrypted_account_store.dart';
import 'package:flutter_auth_qrcode_2fa/data/group_repository.dart';
import 'package:flutter_auth_qrcode_2fa/data/share_history_repository.dart';
import 'package:flutter_auth_qrcode_2fa/data/version_api_client.dart';
import 'package:flutter_auth_qrcode_2fa/domain/group_model.dart';
import 'package:flutter_auth_qrcode_2fa/domain/otp_account.dart';
import 'package:flutter_auth_qrcode_2fa/presentation/deep_link_handler.dart';
import 'package:flutter_auth_qrcode_2fa/presentation/security_service.dart';

final appPreferencesProvider = FutureProvider<AppPreferences>((ref) async {
  return AppPreferences.create();
});

final encryptedStoreProvider = Provider<EncryptedAccountStore>((ref) {
  return EncryptedAccountStore();
});

final accountRepositoryProvider = Provider<AccountRepository>((ref) {
  return AccountRepository(ref.watch(encryptedStoreProvider));
});

final groupRepositoryProvider = FutureProvider<GroupRepository>((ref) async {
  final prefs = await ref.watch(appPreferencesProvider.future);
  return GroupRepository(prefs);
});

final shareHistoryProvider = FutureProvider<ShareHistoryRepository>((ref) async {
  final prefs = await ref.watch(appPreferencesProvider.future);
  return ShareHistoryRepository(prefs);
});

final versionApiProvider = Provider<VersionApiClient>((ref) {
  return VersionApiClient();
});

final securityServiceProvider = FutureProvider<SecurityService>((ref) async {
  final prefs = await ref.watch(appPreferencesProvider.future);
  return SecurityService(prefs);
});

final deepLinkHandlerProvider = Provider<DeepLinkHandler>((ref) {
  return DeepLinkHandler(ref);
});

class AccountsState {
  const AccountsState({
    this.accounts = const [],
    this.loading = true,
    this.selectedGroupId,
    this.error,
  });

  final List<OtpAccount> accounts;
  final bool loading;
  final int? selectedGroupId;
  final String? error;

  AccountsState copyWith({
    List<OtpAccount>? accounts,
    bool? loading,
    int? selectedGroupId,
    bool clearGroupFilter = false,
    String? error,
  }) =>
      AccountsState(
        accounts: accounts ?? this.accounts,
        loading: loading ?? this.loading,
        selectedGroupId:
            clearGroupFilter ? null : (selectedGroupId ?? this.selectedGroupId),
        error: error,
      );
}

class AccountsNotifier extends StateNotifier<AccountsState> {
  AccountsNotifier(this._ref) : super(const AccountsState()) {
    load();
  }

  final Ref _ref;

  AccountRepository get _repo => _ref.read(accountRepositoryProvider);

  Future<void> load() async {
    state = state.copyWith(loading: true, error: null);
    try {
      final list = await _repo.loadAll();
      for (final a in list) {
        a.recomputeOtp();
      }
      _sort(list);
      state = state.copyWith(accounts: list, loading: false);
    } catch (e) {
      state = state.copyWith(loading: false, error: e.toString());
    }
  }

  void _sort(List<OtpAccount> list) {
    list.sort((a, b) {
      if (a.isTop != b.isTop) return a.isTop ? -1 : 1;
      return b.lastUsed.compareTo(a.lastUsed);
    });
  }

  Future<void> add(OtpAccount account) async {
    account.lastUsed = DateTime.now().microsecondsSinceEpoch;
    account.recomputeOtp();
    await _repo.add(account);
    await load();
  }

  Future<void> update(OtpAccount account) async {
    account.recomputeOtp();
    await _repo.update(account);
    await load();
  }

  Future<void> delete(int lastUsed) async {
    await _repo.delete(lastUsed);
    await load();
  }

  Future<void> replaceAll(List<OtpAccount> accounts) async {
    final base = DateTime.now().microsecondsSinceEpoch;
    for (var i = 0; i < accounts.length; i++) {
      final a = accounts[i];
      if (a.lastUsed == 0) {
        a.lastUsed = base + i;
      }
      a.recomputeOtp();
    }
    await _repo.saveAll(accounts);
    await load();
  }

  Future<void> togglePin(OtpAccount account) async {
    account.isTop = !account.isTop;
    await _repo.update(account);
    await load();
  }

  void setGroupFilter(int? groupId) {
    state = state.copyWith(
      selectedGroupId: groupId,
      clearGroupFilter: groupId == null,
    );
  }

  List<OtpAccount> filteredAccounts(List<GroupModel> groups) {
    final groupId = state.selectedGroupId;
    if (groupId == null) return state.accounts;
    GroupModel? group;
    for (final g in groups) {
      if (g.id == groupId) {
        group = g;
        break;
      }
    }
    if (group == null) return state.accounts;
    final byLastUsed = {
      for (final a in state.accounts) a.lastUsed: a,
    };
    return group.codeLastIdList
        .map((id) => byLastUsed[id])
        .whereType<OtpAccount>()
        .toList();
  }
}

final accountsProvider =
    StateNotifierProvider<AccountsNotifier, AccountsState>((ref) {
  return AccountsNotifier(ref);
});

final groupsListProvider = FutureProvider<List<GroupModel>>((ref) async {
  final repo = await ref.watch(groupRepositoryProvider.future);
  final groups = await repo.loadAll();
  final pinned = <GroupModel>[];
  final unpinned = <GroupModel>[];
  for (final g in groups) {
    if (g.pinned) {
      pinned.add(g);
    } else {
      unpinned.add(g);
    }
  }
  return [...pinned, ...unpinned];
});
