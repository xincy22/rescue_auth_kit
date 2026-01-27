import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';

import '../import/otpauth_parser.dart';
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
class VaultSession extends ChangeNotifier {
  final VaultRepository _repo;
  final Uuid _uuid = const Uuid();
  VaultSessionStatus _status = VaultSessionStatus.locked;
  VaultHandle? _handle;

  VaultSession(this._repo);

  VaultSessionStatus get status => _status;
  bool get isUnlocked => _status == VaultSessionStatus.unlocked;

  VaultData get data {
    final h = _handle;
    if (h == null) throw const VaultLockedException();
    return h.data;
  }

  Future<bool> vaultExists() => _repo.vaultFileExists();

  Future<void> createNew({required String password}) async {
    final handle = await _repo.createNewVault(password: password);
    _handle = handle;
    _status = VaultSessionStatus.unlocked;
    notifyListeners();
  }

  Future<void> unlock({required String password}) async {
    final handle = await _repo.open(password: password);
    _handle = handle;
    _status = VaultSessionStatus.unlocked;
    notifyListeners();
  }

  void lock() {
    _handle = null;
    _status = VaultSessionStatus.locked;
    notifyListeners();
  }

  void setData(VaultData newData) {
    final h = _handle;
    if (h == null) throw const VaultLockedException();
    _handle = h.copyWith(data: newData);
    notifyListeners();
  }

  Future<void> save() async {
    final h = _handle;
    if (h == null) throw const VaultLockedException();
    await _repo.save(h);
  }

  Future<void> addTotpFromParsed(ParsedTotp parsed) async {
    final h = _handle;
    if (h == null) throw const VaultLockedException();

    final entry = TotpEntry(
      id: _uuid.v4(),
      issuer: parsed.issuer,
      accountName: parsed.accountName,
      secretBase32: parsed.secretBase32,
      algorithm: parsed.algorithm,
      digits: parsed.digits,
      period: parsed.period,
      createdAt: DateTime.now(),
    );

    final updated = h.data.copyWith(
      totpEntries: <TotpEntry>[...h.data.totpEntries, entry],
    );

    _handle = h.copyWith(data: updated);
    await _repo.save(_handle!);
    notifyListeners();
  }

  Future<void> importVault({
    required Uint8List vaultBytes,
    required String password,
  }) async {
    _handle = await _repo.importBytes(bytes: vaultBytes, password: password);
    _status = VaultSessionStatus.unlocked;
    notifyListeners();
  }

  Future<void> addRecoverySet({
    required String title,
    required List<String> codes,
  }) async {
    final h = _handle;
    if (h == null) throw const VaultLockedException();

    final normalizedCodes = codes
        .map((e) => e.trim())
        .where((e) => e.isNotEmpty)
        .toList(growable: false);

    final set = RecoveryCodeSet(
      id: _uuid.v4(),
      title: title.trim(),
      codes: normalizedCodes,
      createdAt: DateTime.now(),
    );

    final updated = h.data.copyWith(
      recoveryCodeSets: <RecoveryCodeSet>[...h.data.recoveryCodeSets, set],
    );

    _handle = h.copyWith(data: updated);
    await _repo.save(_handle!);
    notifyListeners();
  }

  Future<void> removeRecoverySet(String id) async {
    final h = _handle;
    if (h == null) throw const VaultLockedException();

    final updated = h.data.copyWith(
      recoveryCodeSets: h.data.recoveryCodeSets
          .where((e) => e.id != id)
          .toList(growable: false),
    );

    _handle = h.copyWith(data: updated);
    await _repo.save(_handle!);
    notifyListeners();
  }
}
