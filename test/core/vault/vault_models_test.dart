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
    );

    final json = data.toJson();
    final decoded = VaultData.fromJson(json);

    expect(decoded.schemaVersion, data.schemaVersion);
    expect(decoded.totpEntries.length, 1);
    expect(decoded.recoveryCodeSets.length, 1);

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
  });
}
