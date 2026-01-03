import 'dart:async';

import 'vault_models.dart';
import 'vault_repository.dart';

enum VaultSessionStatus { locked, unlocked }

class VaultLockedException implements Exception {
  const VaultLockedException();
  @override
  String toString() => 'VaultLockedException: vault is locked';
}

/// In-memory session state. UI should talk to this instead of directly using
/// repository/crypto.
class VaultSession {
  final VaultRepository _repo;
  VaultSessionStatus _status = VaultSessionStatus.locked;
  VaultHandle? _handle;

  VaultSession(this._repo);

  VaultSessionStatus get status => _status;
  bool get isUnlocked => _status == VaultSessionStatus.unlocked;

  /// Returns current decrypted data when unlocked; throws if locked.
  VaultData get data {
    final h = _handle;
    if (h == null) throw const VaultLockedException();
    return h.data;
  }

  Future<bool> vaultExists() => _repo.vaultFileExists();

  /// Create a brand new vault file on disk and unlock session.
  Future<void> createNew({required String password}) async {
    final handle = await _repo.createNewVault(password: password);
    _handle = handle;
    _status = VaultSessionStatus.unlocked;
  }

  /// Open existing vault and unlock session.
  ///
  /// Throws:
  /// - [VaultIoException] (file not found)
  /// - [VaultFormatException] (corrupted/unsupported)
  /// - [VaultAuthException] (wrong password / tampered ciphertext)
  Future<void> unlock({required String password}) async {
    final handle = await _repo.open(password: password);
    _handle = handle;
    _status = VaultSessionStatus.unlocked;
  }

  /// Drop decrypted material from memory (best-effort).
  ///
  /// Note: Dart GC is nondeterministic; we reduce exposure by removing references.
  void lock() {
    _handle = null;
    _status = VaultSessionStatus.locked;
  }

  /// Replace current data in memory (unlocked only). Does NOT persist automatically.
  void setData(VaultData newData) {
    final h = _handle;
    if (h == null) throw const VaultLockedException();
    _handle = h.copyWith(data: newData);
  }

  /// Persist current data to the vault file (unlocked only).
  Future<void> save() async {
    final h = _handle;
    if (h == null) throw const VaultLockedException();
    await _repo.save(h);
  }
}
