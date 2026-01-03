import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;
import 'package:rescue_auth_kit/core/vault/vault_models.dart';
import 'package:rescue_auth_kit/core/vault/vault_repository.dart';

void main() {
  test('createNewVault -> open works with correct password', () async {
    final dir = await Directory.systemTemp.createTemp('rak_vault_test_');

    try {
      final vaultPath = p.join(dir.path, 'vault.rakvault');
      final repo = VaultRepository.forPath(vaultFilePath: vaultPath);

      final handle = await repo.createNewVault(password: 'testpassword');
      expect(await repo.vaultFileExists(), isTrue);
      expect(handle.data.totpEntries, isEmpty);

      final opened = await repo.open(password: 'testpassword');
      expect(opened.data.totpEntries, isEmpty);
      expect(opened.data.recoveryCodeSets, isEmpty);
    } finally {
      await dir.delete(recursive: true);
    }
  });

  test('open throws VaultAuthException on wrong password', () async {
    final dir = await Directory.systemTemp.createTemp('rak_vault_test_');

    try {
      final vaultPath = p.join(dir.path, 'vault.rakvault');
      final repo = VaultRepository.forPath(vaultFilePath: vaultPath);

      await repo.createNewVault(password: 'correctpassword');

      await expectLater(
        repo.open(password: 'wrongpassword'),
        throwsA(isA<VaultAuthException>()),
      );
    } finally {
      await dir.delete(recursive: true);
    }
  });

  test('save persists data changes', () async {
    final dir = await Directory.systemTemp.createTemp('rak_vault_test_');

    try {
      final vaultPath = p.join(dir.path, 'vault.rakvault');
      final repo = VaultRepository.forPath(vaultFilePath: vaultPath);

      var handle = await repo.createNewVault(password: 'testpassword');

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

      final updated = handle.data.copyWith(
        totpEntries: [...handle.data.totpEntries, entry],
      );

      handle = handle.copyWith(data: updated);
      await repo.save(handle);

      final reopened = await repo.open(password: 'testpassword');
      expect(reopened.data.totpEntries.length, 1);
      expect(reopened.data.totpEntries.single.issuer, 'Example');
    } finally {
      await dir.delete(recursive: true);
    }
  });

  test('exportBytes/importBytes roundtrip', () async {
    final dir1 = await Directory.systemTemp.createTemp('rak_vault_test_src_');
    final dir2 = await Directory.systemTemp.createTemp('rak_vault_test_dst_');

    try {
      final srcPath = p.join(dir1.path, 'vault.rakvault');
      final dstPath = p.join(dir2.path, 'vault.rakvault');

      final repo1 = VaultRepository.forPath(vaultFilePath: srcPath);
      final repo2 = VaultRepository.forPath(vaultFilePath: dstPath);

      await repo1.createNewVault(password: 'testpassword');
      final bytes = await repo1.exportBytes();
      expect(bytes, isA<Uint8List>());

      final imported = await repo2.importBytes(
        bytes: bytes,
        password: 'testpassword',
      );
      expect(await repo2.vaultFileExists(), isTrue);
      expect(imported.data.schemaVersion, vaultDataSchemaVersion);

      final opened = await repo2.open(password: 'testpassword');
      expect(opened.data.totpEntries, isEmpty);
    } finally {
      await dir1.delete(recursive: true);
      await dir2.delete(recursive: true);
    }
  });
}
