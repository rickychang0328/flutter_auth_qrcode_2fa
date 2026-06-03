import 'package:flutter_auth_qrcode_2fa/data/encrypted_account_store.dart';
import 'package:flutter_auth_qrcode_2fa/domain/otp_account.dart';

class AccountRepository {
  AccountRepository(this._store);

  final EncryptedAccountStore _store;

  Future<List<OtpAccount>> loadAll() => _store.loadAll();

  Future<void> saveAll(List<OtpAccount> accounts) => _store.saveAll(accounts);

  Future<void> add(OtpAccount account) => _store.add(account);

  Future<void> update(OtpAccount account) => _store.update(account);

  Future<void> delete(int lastUsed) => _store.delete(lastUsed);

  Future<void> wipe() => _store.wipe();

  OtpAccount? findDuplicate(List<OtpAccount> all, OtpAccount candidate) {
    for (final existing in all) {
      if (existing.secretText == candidate.secretText &&
          existing.issuer == candidate.issuer &&
          existing.account == candidate.account &&
          existing.type == candidate.type) {
        return existing;
      }
    }
    return null;
  }
}
