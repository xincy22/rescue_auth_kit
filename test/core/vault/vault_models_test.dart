import 'package:flutter_test/flutter_test.dart';
import 'package:rescue_auth_kit/core/vault/vault_models.dart';

void main() {
  test('VaultData toJson/fromJson roundtrip', () {
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

    final rec = RecoveryCodeSet(
      id: 'r1',
      title: 'Example Recovery Codes',
      codes: const ['code1', 'code2', 'code3'],
      createdAt: DateTime.parse('2026-01-01T12:00:00Z'),
    );

    final data = VaultData(
      schemaVersion: vaultDataSchemaVersion,
      totpEntries: [entry],
      recoveryCodeSets: [rec],
      developerSettings: const DeveloperSettings(enabled: true),
      developerEntries: [
        DeveloperEntry(
          id: 'd1',
          type: DeveloperEntryType.androidSigningKey,
          title: 'Android Signing',
          notes: 'Release upload key',
          createdAt: DateTime.parse('2026-01-01T12:00:00Z'),
          updatedAt: DateTime.parse('2026-01-01T12:00:00Z'),
          payload: const {
            'projectName': 'RescueAuthKit',
            'packageName': 'com.xincy.rescue_auth_kit',
            'keystoreFileName': 'upload-keystore.jks',
            'keystoreBytesBase64': 'AQIDBA==',
            'storePassword': 'store-pass',
            'keyAlias': 'upload',
            'keyPassword': 'key-pass',
          },
        ),
        DeveloperEntry(
          id: 'd2',
          type: DeveloperEntryType.apiCredential,
          title: 'API',
          notes: '',
          createdAt: DateTime.parse('2026-01-01T12:00:00Z'),
          updatedAt: DateTime.parse('2026-01-01T12:00:00Z'),
          payload: const {
            'serviceName': 'Example',
            'accountName': 'user@example.com',
            'apiKey': 'key',
            'apiSecret': 'secret',
          },
        ),
        DeveloperEntry(
          id: 'd3',
          type: DeveloperEntryType.sshKey,
          title: 'SSH',
          notes: '',
          createdAt: DateTime.parse('2026-01-01T12:00:00Z'),
          updatedAt: DateTime.parse('2026-01-01T12:00:00Z'),
          payload: const {
            'keyName': 'github',
            'publicKey': 'ssh-ed25519 public',
            'privateKey': 'private',
            'passphrase': 'phrase',
          },
        ),
        DeveloperEntry(
          id: 'd4',
          type: DeveloperEntryType.envVarSet,
          title: 'Env',
          notes: '',
          createdAt: DateTime.parse('2026-01-01T12:00:00Z'),
          updatedAt: DateTime.parse('2026-01-01T12:00:00Z'),
          payload: const {
            'projectName': 'Example',
            'variables': [
              {'name': 'API_KEY', 'value': 'value'},
            ],
          },
        ),
        DeveloperEntry(
          id: 'd5',
          type: DeveloperEntryType.genericSecret,
          title: 'Generic',
          notes: '',
          createdAt: DateTime.parse('2026-01-01T12:00:00Z'),
          updatedAt: DateTime.parse('2026-01-01T12:00:00Z'),
          payload: const {
            'fields': [
              {'label': 'token', 'value': 'value'},
            ],
          },
        ),
      ],
    );

    final json = data.toJson();
    final decoded = VaultData.fromJson(json);

    expect(decoded.schemaVersion, data.schemaVersion);
    expect(decoded.totpEntries.length, 1);
    expect(decoded.recoveryCodeSets.length, 1);
    expect(decoded.developerSettings.enabled, isTrue);
    expect(decoded.developerEntries.length, 5);

    final e2 = decoded.totpEntries.single;
    expect(e2.id, entry.id);
    expect(e2.issuer, entry.issuer);
    expect(e2.accountName, entry.accountName);
    expect(e2.secretBase32, entry.secretBase32);
    expect(e2.algorithm, entry.algorithm);
    expect(e2.digits, entry.digits);
    expect(e2.period, entry.period);
    expect(e2.createdAt.toIso8601String(), entry.createdAt.toIso8601String());

    final r2 = decoded.recoveryCodeSets.single;
    expect(r2.id, rec.id);
    expect(r2.title, rec.title);
    expect(r2.codes, rec.codes);
    expect(r2.createdAt.toIso8601String(), rec.createdAt.toIso8601String());

    final developerTypes = decoded.developerEntries.map((e) => e.type).toSet();
    expect(developerTypes, DeveloperEntryType.values.toSet());
    expect(decoded.developerEntries.first.payload['keyAlias'], 'upload');
  });

  test('schema v1 vault data defaults developer backup off', () {
    final decoded = VaultData.fromJson({
      'schemaVersion': 1,
      'totpEntries': const [],
      'recoveryCodeSets': const [],
    });

    expect(decoded.schemaVersion, 1);
    expect(decoded.developerSettings.enabled, isFalse);
    expect(decoded.developerEntries, isEmpty);
    expect(decoded.copyWith().schemaVersion, vaultDataSchemaVersion);
  });
}
