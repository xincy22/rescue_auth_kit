import 'dart:convert';
import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:rescue_auth_kit/core/vault/vault_migrator.dart';
import 'package:rescue_auth_kit/core/vault/vault_models.dart';
import 'package:rescue_auth_kit/core/vault/vault_repository.dart';

// ---------------------------------------------------------------------------
// Property-based migration tests for the v3 (provider/account/credential)
// model. Properties asserted:
//   - Property 4 (totality): migrate(j2) does not throw and yields v3.
//   - Property 5 (secret preservation): every legacy TOTP secret and every
//     legacy recovery code (with original ordering) is reachable in the
//     migrated VaultData.
//   - Property 6 (idempotence): migrate(round-trip(migrate(j2))) == migrate(j2).
//   - Property 7 (count law): the number of accounts equals
//     totpEntries.length + recoveryCodeSets.length.
//   - Already-v3 fixture is returned structurally equal to VaultData.fromJson.
//   - Future-version fixture (schemaVersion: 99) throws VaultFormatException.
// ---------------------------------------------------------------------------

const _alphanumeric =
    'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789';
const _base32Chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ234567';

String _randomString(Random rng, int minLen, int maxLen,
    {String chars = _alphanumeric}) {
  final len = minLen + rng.nextInt(maxLen - minLen + 1);
  return String.fromCharCodes(
    List.generate(len, (_) => chars.codeUnitAt(rng.nextInt(chars.length))),
  );
}

DateTime _randomDateTime(Random rng) {
  final startSec = DateTime.utc(2020).millisecondsSinceEpoch ~/ 1000;
  final endSec = DateTime.utc(2030).millisecondsSinceEpoch ~/ 1000;
  final sec = startSec + rng.nextInt(endSec - startSec);
  return DateTime.fromMillisecondsSinceEpoch(sec * 1000, isUtc: true);
}

String _randomAlgorithm(Random rng) {
  const algos = ['SHA1', 'SHA256', 'SHA512'];
  return algos[rng.nextInt(algos.length)];
}

Map<String, dynamic> _genTotpEntryJson(Random rng) {
  return <String, dynamic>{
    'id': 'totp-${rng.nextInt(1 << 32).toRadixString(16)}',
    'issuer': rng.nextBool() ? _randomString(rng, 1, 20) : '',
    'accountName': rng.nextBool() ? _randomString(rng, 1, 20) : '',
    'secretBase32': _randomString(rng, 8, 32, chars: _base32Chars),
    'algorithm': _randomAlgorithm(rng),
    'digits': 6 + rng.nextInt(5),
    'period': 15 + rng.nextInt(106),
    'createdAt': _randomDateTime(rng).toIso8601String(),
  };
}

Map<String, dynamic> _genRecoveryCodeSetJson(Random rng) {
  final codeCount = rng.nextInt(10);
  return <String, dynamic>{
    'id': 'rc-${rng.nextInt(1 << 32).toRadixString(16)}',
    'title': rng.nextBool() ? _randomString(rng, 1, 25) : '',
    'codes': List.generate(codeCount, (_) => _randomString(rng, 4, 16)),
    'createdAt': _randomDateTime(rng).toIso8601String(),
  };
}

Map<String, dynamic> genV2Json(Random rng) {
  final totpCount = rng.nextInt(6);
  final recoveryCount = rng.nextInt(5);
  return <String, dynamic>{
    'schemaVersion': 2,
    'totpEntries':
        List.generate(totpCount, (_) => _genTotpEntryJson(rng)),
    'recoveryCodeSets':
        List.generate(recoveryCount, (_) => _genRecoveryCodeSetJson(rng)),
    'developerSettings': <String, dynamic>{'enabled': rng.nextBool()},
    'developerEntries': const <Map<String, dynamic>>[],
  };
}

void main() {
  late VaultMigrator migrator;
  setUp(() {
    migrator = VaultMigrator();
  });

  group('Property 4 + 7: totality and account count law', () {
    test('migrate is total over v2 inputs and obeys count law', () {
      final rng = Random(0xC0DE);
      for (int i = 0; i < 100; i++) {
        final j2 = genV2Json(rng);
        late VaultData out;
        expect(() => out = migrator.migrate(j2), returnsNormally,
            reason: 'iter $i');
        expect(out.schemaVersion, 3);
        final totpCount = (j2['totpEntries'] as List).length;
        final recoveryCount = (j2['recoveryCodeSets'] as List).length;
        expect(out.accounts.length, totpCount + recoveryCount,
            reason: 'count law violated at iter $i');
      }
    });
  });

  group('Property 5: secret preservation', () {
    test('every TOTP secret is reachable by id in migrated accounts', () {
      final rng = Random(0xBEEF);
      for (int i = 0; i < 50; i++) {
        final j2 = genV2Json(rng);
        final out = migrator.migrate(j2);

        for (final entry in j2['totpEntries'] as List) {
          final m = Map<String, dynamic>.from(entry as Map);
          final id = m['id'] as String;
          final secret = m['secretBase32'] as String;
          final cred = out.accounts
              .expand((a) => a.credentials)
              .whereType<TotpCredential>()
              .firstWhere(
                (c) => c.id == id,
                orElse: () => throw StateError(
                  'Missing migrated TOTP for id=$id at iter $i',
                ),
              );
          expect(cred.secretBase32, secret,
              reason: 'secret bytes lost at iter $i id=$id');
        }
      }
    });

    test('every recovery code set survives with ordered codes', () {
      final rng = Random(0xFACE);
      for (int i = 0; i < 50; i++) {
        final j2 = genV2Json(rng);
        final out = migrator.migrate(j2);

        for (final setJson in j2['recoveryCodeSets'] as List) {
          final m = Map<String, dynamic>.from(setJson as Map);
          final id = m['id'] as String;
          final codes = (m['codes'] as List).map((e) => e.toString()).toList();
          final cred = out.accounts
              .expand((a) => a.credentials)
              .whereType<RecoveryCodesCredential>()
              .firstWhere(
                (c) => c.id == id,
                orElse: () => throw StateError(
                  'Missing migrated recovery for id=$id at iter $i',
                ),
              );
          expect(cred.codes, orderedEquals(codes),
              reason: 'codes ordering lost at iter $i id=$id');
        }
      }
    });
  });

  group('Property 6: idempotence', () {
    test('migrate(round-trip(migrate(j2))) == migrate(j2)', () {
      final rng = Random(0xC1A0);
      for (int i = 0; i < 50; i++) {
        final j2 = genV2Json(rng);
        final once = migrator.migrate(j2);
        final twice = migrator.migrate(
          jsonDecode(jsonEncode(once.toJson())) as Map<String, dynamic>,
        );
        expect(twice, equals(once), reason: 'idempotence broke at iter $i');
      }
    });
  });

  group('Already-v3 fixture passes through unchanged', () {
    test('migrate of a v3 payload equals VaultData.fromJson of the same', () {
      final v3 = <String, dynamic>{
        'schemaVersion': 3,
        'providers': [
          {
            'id': 'p1',
            'name': 'GitHub',
            'createdAt': '2026-01-01T00:00:00.000Z',
            'updatedAt': '2026-01-01T00:00:00.000Z',
          },
        ],
        'accounts': [
          {
            'id': 'a1',
            'providerId': 'p1',
            'displayName': 'me@example.com',
            'createdAt': '2026-01-01T00:00:00.000Z',
            'updatedAt': '2026-01-01T00:00:00.000Z',
            'credentials': [
              {
                'kind': 'totp',
                'id': 't1',
                'createdAt': '2026-01-01T00:00:00.000Z',
                'secretBase32': 'JBSWY3DPEHPK3PXP',
                'algorithm': 'SHA1',
                'digits': 6,
                'period': 30,
              },
            ],
          },
        ],
        'developerSettings': {'enabled': false},
        'developerEntries': [],
      };

      final fromMigrator = migrator.migrate(v3);
      final fromDirect = VaultData.fromJson(v3);
      expect(fromMigrator, equals(fromDirect));
    });
  });

  group('Future-version guard', () {
    test('migrate throws VaultFormatException for schemaVersion 99', () {
      final fixture = <String, dynamic>{
        'schemaVersion': 99,
        'providers': [],
        'accounts': [],
        'developerSettings': {'enabled': false},
        'developerEntries': [],
      };
      expect(
        () => migrator.migrate(fixture),
        throwsA(isA<VaultFormatException>().having(
          (e) => e.message,
          'message',
          contains('99'),
        )),
      );
    });
  });
}
