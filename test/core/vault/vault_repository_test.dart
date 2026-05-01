import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;
import 'package:rescue_auth_kit/core/crypto/vault_crypto.dart';
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

  test(
    'open silently upgrades schema v1 vault file to current schema',
    () async {
      final dir = await Directory.systemTemp.createTemp(
        'rak_vault_test_legacy_',
      );

      try {
        final vaultPath = p.join(dir.path, 'vault.rakvault');
        const password = 'testpassword';
        await _writeLegacySchema1Vault(
          vaultPath: vaultPath,
          password: password,
        );
        final beforeBytes = await File(vaultPath).readAsBytes();

        final repo = VaultRepository.forPath(vaultFilePath: vaultPath);
        final opened = await repo.open(password: password);
        final afterBytes = await File(vaultPath).readAsBytes();

        expect(opened.data.schemaVersion, vaultDataSchemaVersion);
        expect(opened.data.developerSettings.enabled, isFalse);
        expect(opened.data.developerEntries, isEmpty);
        expect(afterBytes, isNot(beforeBytes));

        final rawPayload = await _decryptVaultPayload(
          bytes: Uint8List.fromList(afterBytes),
          password: password,
        );
        expect(rawPayload['schemaVersion'], vaultDataSchemaVersion);
        expect(rawPayload['developerSettings'], {'enabled': false});
        expect(rawPayload['developerEntries'], isEmpty);
      } finally {
        await dir.delete(recursive: true);
      }
    },
  );
}

Future<void> _writeLegacySchema1Vault({
  required String vaultPath,
  required String password,
}) async {
  final crypto = VaultCrypto();
  final salt = crypto.newSalt();
  final kdf = VaultKdfParams.forTesting(salt: salt);
  final key = await crypto.deriveKeyFromPassword(
    password: password,
    params: kdf,
  );
  final legacyJson = jsonEncode({
    'schemaVersion': 1,
    'totpEntries': const [],
    'recoveryCodeSets': const [],
  });
  final vaultFile = await crypto.encryptToFile(
    cleartextJsonBytes: Uint8List.fromList(utf8.encode(legacyJson)),
    key: key,
    kdfParams: kdf,
  );

  final file = File(vaultPath);
  await file.parent.create(recursive: true);
  await file.writeAsBytes(vaultFile.encode(), flush: true);
}

Future<Map<String, dynamic>> _decryptVaultPayload({
  required Uint8List bytes,
  required String password,
}) async {
  final crypto = VaultCrypto();
  final vaultFile = VaultFile.decode(bytes);
  final key = await crypto.deriveKeyFromPassword(
    password: password,
    params: vaultFile.kdf,
  );
  final clearBytes = await crypto.decryptFile(file: vaultFile, key: key);
  return jsonDecode(utf8.decode(clearBytes)) as Map<String, dynamic>;
}
