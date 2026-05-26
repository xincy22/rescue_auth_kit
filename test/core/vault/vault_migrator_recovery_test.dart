import 'package:flutter_test/flutter_test.dart';
import 'package:rescue_auth_kit/core/vault/vault_migrator.dart';
import 'package:rescue_auth_kit/core/vault/vault_models.dart';

void main() {
  late VaultMigrator migrator;

  setUp(() {
    migrator = VaultMigrator();
  });

  group(
    'VaultMigrator - RecoveryCodeSet → ServiceProvider+Account+RecoveryCodesCredential',
    () {
      test('single recovery set creates one provider, one account, one cred',
          () {
        final v2Json = <String, dynamic>{
          'schemaVersion': 2,
          'totpEntries': [],
          'recoveryCodeSets': [
            {
              'id': 'recovery-1',
              'title': 'GitHub Backup Codes',
              'codes': ['abc123', 'def456', 'ghi789'],
              'createdAt': '2024-01-20T14:00:00.000Z',
            },
          ],
          'developerSettings': {'enabled': false},
          'developerEntries': [],
        };

        final result = migrator.migrate(v2Json);
        expect(result.providers, hasLength(1));
        expect(result.accounts, hasLength(1));

        final provider = result.providers.single;
        final account = result.accounts.single;
        expect(provider.name, 'GitHub Backup Codes');
        expect(account.providerId, provider.id);
        expect(account.displayName, 'GitHub Backup Codes');

        final cred =
            account.credentials.single as RecoveryCodesCredential;
        expect(cred.id, 'recovery-1');
        expect(cred.codes, ['abc123', 'def456', 'ghi789']);
      });

      test('uses "Recovery codes" fallback when title is empty', () {
        final v2Json = <String, dynamic>{
          'schemaVersion': 2,
          'totpEntries': [],
          'recoveryCodeSets': [
            {
              'id': 'recovery-2',
              'title': '',
              'codes': ['code1', 'code2'],
              'createdAt': '2024-02-10T09:00:00.000Z',
            },
          ],
          'developerSettings': {'enabled': false},
          'developerEntries': [],
        };

        final result = migrator.migrate(v2Json);
        expect(result.providers.single.name, 'Recovery codes');
        expect(result.accounts.single.displayName, 'Recovery codes');
      });

      test('each recovery set gets its own provider (no merging)', () {
        final v2Json = <String, dynamic>{
          'schemaVersion': 2,
          'totpEntries': [],
          'recoveryCodeSets': [
            {
              'id': 'first-rc',
              'title': 'Alpha Recovery',
              'codes': ['a1'],
              'createdAt': '2024-01-01T00:00:00.000Z',
            },
            {
              'id': 'second-rc',
              'title': 'Alpha Recovery',
              'codes': ['a2'],
              'createdAt': '2024-01-02T00:00:00.000Z',
            },
          ],
          'developerSettings': {'enabled': false},
          'developerEntries': [],
        };

        final result = migrator.migrate(v2Json);
        // Two recovery sets even with same title -> two distinct providers.
        expect(result.providers, hasLength(2));
        expect(result.accounts, hasLength(2));
        expect(result.providers[0].id, isNot(result.providers[1].id));
      });

      test('preserves codes list order', () {
        final codes = [
          'zebra-code',
          'alpha-code',
          'middle-code',
          '123-numeric',
          'UPPER-CASE',
        ];

        final v2Json = <String, dynamic>{
          'schemaVersion': 2,
          'totpEntries': [],
          'recoveryCodeSets': [
            {
              'id': 'rc-order',
              'title': 'Order Test',
              'codes': codes,
              'createdAt': '2024-03-01T00:00:00.000Z',
            },
          ],
          'developerSettings': {'enabled': false},
          'developerEntries': [],
        };

        final result = migrator.migrate(v2Json);
        final cred = result.accounts.single.credentials.single
            as RecoveryCodesCredential;
        expect(cred.codes, orderedEquals(codes));
      });

      test('combined TOTP + recovery: TOTP providers come first', () {
        final v2Json = <String, dynamic>{
          'schemaVersion': 2,
          'totpEntries': [
            {
              'id': 'totp-a',
              'issuer': 'ServiceA',
              'accountName': 'user-a',
              'secretBase32': 'AAAA',
              'algorithm': 'SHA1',
              'digits': 6,
              'period': 30,
              'createdAt': '2024-01-01T00:00:00.000Z',
            },
            {
              'id': 'totp-b',
              'issuer': 'ServiceB',
              'accountName': 'user-b',
              'secretBase32': 'BBBB',
              'algorithm': 'SHA1',
              'digits': 6,
              'period': 30,
              'createdAt': '2024-01-02T00:00:00.000Z',
            },
          ],
          'recoveryCodeSets': [
            {
              'id': 'rc-x',
              'title': 'Recovery X',
              'codes': ['x1', 'x2'],
              'createdAt': '2024-01-03T00:00:00.000Z',
            },
            {
              'id': 'rc-y',
              'title': 'Recovery Y',
              'codes': ['y1', 'y2'],
              'createdAt': '2024-01-04T00:00:00.000Z',
            },
          ],
          'developerSettings': {'enabled': false},
          'developerEntries': [],
        };

        final result = migrator.migrate(v2Json);
        // 2 TOTP providers + 2 recovery providers = 4 providers
        expect(result.providers, hasLength(4));
        expect(result.providers.map((p) => p.name).toList(),
            ['ServiceA', 'ServiceB', 'Recovery X', 'Recovery Y']);

        // 2 + 2 = 4 accounts
        expect(result.accounts, hasLength(4));
      });

      test('handles empty recoveryCodeSets list', () {
        final v2Json = <String, dynamic>{
          'schemaVersion': 2,
          'totpEntries': [],
          'recoveryCodeSets': [],
          'developerSettings': {'enabled': false},
          'developerEntries': [],
        };
        final result = migrator.migrate(v2Json);
        expect(result.providers, isEmpty);
        expect(result.accounts, isEmpty);
      });

      test('recovery set with empty codes still produces a credential', () {
        final v2Json = <String, dynamic>{
          'schemaVersion': 2,
          'totpEntries': [],
          'recoveryCodeSets': [
            {
              'id': 'rc-empty',
              'title': 'Empty Codes',
              'codes': [],
              'createdAt': '2024-04-01T00:00:00.000Z',
            },
          ],
          'developerSettings': {'enabled': false},
          'developerEntries': [],
        };
        final result = migrator.migrate(v2Json);
        final cred = result.accounts.single.credentials.single
            as RecoveryCodesCredential;
        expect(cred.codes, isEmpty);
      });
    },
  );
}
