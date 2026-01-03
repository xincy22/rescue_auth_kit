import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;

import 'package:rescue_auth_kit/core/vault/vault_models.dart';
import 'package:rescue_auth_kit/core/vault/vault_repository.dart';
import 'package:rescue_auth_kit/core/vault/vault_session.dart';

void main() {
  test('createNew -> lock -> unlock works', () async {
    final dir = await Directory.systemTemp.createTemp('rak_vault_test_');

    try {
      final vaultPath = p.join(dir.path, 'vault.rakvault');
      final repo = VaultRepository.forPath(vaultFilePath: vaultPath);
      final session = VaultSession(repo);

      expect(await session.vaultExists(), isFalse);
      expect(session.isUnlocked, isFalse);

      await session.createNew(password: 'testpassword');
      expect(await session.vaultExists(), isTrue);
      expect(session.isUnlocked, isTrue);
      expect(session.data.totpEntries, isEmpty);

      session.lock();
      expect(session.isUnlocked, isFalse);

      await session.unlock(password: 'testpassword');
      expect(session.isUnlocked, isTrue);
      expect(session.data.totpEntries, isEmpty);
    } finally {
      await dir.delete(recursive: true);
    }
  });

  test('unlock with wrong password throws VaultAuthException', () async {
    final dir = await Directory.systemTemp.createTemp('rak_vault_test_');

    try {
      final vaultPath = p.join(dir.path, 'vault.rakvault');
      final repo = VaultRepository.forPath(vaultFilePath: vaultPath);
      final session = VaultSession(repo);

      await session.createNew(password: 'correctpassword');
      session.lock();

      await expectLater(
        session.unlock(password: 'wrongpassword'),
        throwsA(isA<VaultAuthException>()),
      );
    } finally {
      await dir.delete(recursive: true);
    }
  });

  test('setData/save persists changes', () async {
    final dir = await Directory.systemTemp.createTemp('rak_vault_test_');

    try {
      final vaultPath = p.join(dir.path, 'vault.rakvault');
      final repo = VaultRepository.forPath(vaultFilePath: vaultPath);
      final session = VaultSession(repo);

      await session.createNew(password: 'testpassword');

      final entry = TotpEntry(
        id: 't1',
        issuer: 'Example',
        accountName: 'user@example.com',
        secretBase32: 'JBSWY3DPEHPK3PXP',
        algorithm: TotpHashAlgorithm.sha1,
        digits: 6,
        period: 30,
        createdAt: DateTime.parse('2026-01-01T12:00:00Z'),
      );

      session.setData(session.data.copyWith(totpEntries: [entry]));
      await session.save();

      session.lock();
      await session.unlock(password: 'testpassword');

      expect(session.data.totpEntries.length, 1);
      expect(session.data.totpEntries.single.issuer, 'Example');
    } finally {
      await dir.delete(recursive: true);
    }
  });
}
