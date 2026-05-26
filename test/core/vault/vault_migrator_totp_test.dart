import 'package:flutter_test/flutter_test.dart';
import 'package:rescue_auth_kit/core/vault/vault_migrator.dart';
import 'package:rescue_auth_kit/core/vault/vault_models.dart';

void main() {
  late VaultMigrator migrator;

  setUp(() {
    migrator = VaultMigrator();
  });

  group('VaultMigrator - TotpEntry → ServiceProvider+Account+TotpCredential',
      () {
    test('single TOTP entry creates one provider, one account, one credential',
        () {
      final v2Json = <String, dynamic>{
        'schemaVersion': 2,
        'totpEntries': [
          {
            'id': 'totp-1',
            'issuer': 'GitHub',
            'accountName': 'user@example.com',
            'secretBase32': 'JBSWY3DPEHPK3PXP',
            'algorithm': 'SHA1',
            'digits': 6,
            'period': 30,
            'createdAt': '2024-01-15T10:30:00.000Z',
          },
        ],
        'recoveryCodeSets': [],
        'developerSettings': {'enabled': false},
        'developerEntries': [],
      };

      final result = migrator.migrate(v2Json);

      expect(result.schemaVersion, 3);
      expect(result.providers, hasLength(1));
      expect(result.accounts, hasLength(1));

      final provider = result.providers.single;
      final account = result.accounts.single;
      expect(provider.name, 'GitHub');
      expect(account.providerId, provider.id);
      expect(account.displayName, 'user@example.com');
      expect(account.createdAt, DateTime.parse('2024-01-15T10:30:00.000Z'));

      final cred = account.credentials.single as TotpCredential;
      expect(cred.id, 'totp-1');
      expect(cred.secretBase32, 'JBSWY3DPEHPK3PXP');
      expect(cred.algorithm, TotpHashAlgorithm.sha1);
      expect(cred.digits, 6);
      expect(cred.period, 30);
    });

    test('uses accountName as displayName when issuer is empty', () {
      final v2Json = <String, dynamic>{
        'schemaVersion': 2,
        'totpEntries': [
          {
            'id': 'totp-2',
            'issuer': '',
            'accountName': 'my-account',
            'secretBase32': 'ABCDEFGH',
            'algorithm': 'SHA256',
            'digits': 8,
            'period': 60,
            'createdAt': '2024-02-01T12:00:00.000Z',
          },
        ],
        'recoveryCodeSets': [],
        'developerSettings': {'enabled': false},
        'developerEntries': [],
      };

      final result = migrator.migrate(v2Json);
      expect(result.providers.single.name, 'Untitled');
      expect(result.accounts.single.displayName, 'my-account');
    });

    test('uses "Account" displayName when both issuer and accountName empty',
        () {
      final v2Json = <String, dynamic>{
        'schemaVersion': 2,
        'totpEntries': [
          {
            'id': 'totp-3',
            'issuer': '',
            'accountName': '',
            'secretBase32': 'XYZXYZ',
            'algorithm': 'SHA512',
            'digits': 6,
            'period': 30,
            'createdAt': '2024-03-01T08:00:00.000Z',
          },
        ],
        'recoveryCodeSets': [],
        'developerSettings': {'enabled': false},
        'developerEntries': [],
      };

      final result = migrator.migrate(v2Json);
      expect(result.providers.single.name, 'Untitled');
      expect(result.accounts.single.displayName, 'Account');
    });

    test(
        'multiple TOTP entries with the SAME issuer share a single provider',
        () {
      final v2Json = <String, dynamic>{
        'schemaVersion': 2,
        'totpEntries': [
          {
            'id': 'a',
            'issuer': 'GitHub',
            'accountName': 'user-a',
            'secretBase32': 'AAA',
            'algorithm': 'SHA1',
            'digits': 6,
            'period': 30,
            'createdAt': '2024-01-01T00:00:00.000Z',
          },
          {
            'id': 'b',
            'issuer': 'GitHub',
            'accountName': 'user-b',
            'secretBase32': 'BBB',
            'algorithm': 'SHA1',
            'digits': 6,
            'period': 30,
            'createdAt': '2024-01-02T00:00:00.000Z',
          },
        ],
        'recoveryCodeSets': [],
        'developerSettings': {'enabled': false},
        'developerEntries': [],
      };

      final result = migrator.migrate(v2Json);
      expect(result.providers, hasLength(1));
      expect(result.accounts, hasLength(2));
      expect(result.accounts[0].providerId, result.providers.single.id);
      expect(result.accounts[1].providerId, result.providers.single.id);
      expect(result.accounts.map((a) => a.displayName).toList(),
          ['user-a', 'user-b']);
    });

    test(
        'issuer matching is case-insensitive and trim-tolerant',
        () {
      final v2Json = <String, dynamic>{
        'schemaVersion': 2,
        'totpEntries': [
          {
            'id': 'a',
            'issuer': 'GitHub',
            'accountName': 'user-a',
            'secretBase32': 'AAA',
            'algorithm': 'SHA1',
            'digits': 6,
            'period': 30,
            'createdAt': '2024-01-01T00:00:00.000Z',
          },
          {
            'id': 'b',
            'issuer': '  github  ',
            'accountName': 'user-b',
            'secretBase32': 'BBB',
            'algorithm': 'SHA1',
            'digits': 6,
            'period': 30,
            'createdAt': '2024-01-02T00:00:00.000Z',
          },
        ],
        'recoveryCodeSets': [],
        'developerSettings': {'enabled': false},
        'developerEntries': [],
      };

      final result = migrator.migrate(v2Json);
      expect(result.providers, hasLength(1));
      // Provider name is the FIRST non-empty issuer string seen.
      expect(result.providers.single.name, 'GitHub');
    });

    test('different issuers create separate providers', () {
      final v2Json = <String, dynamic>{
        'schemaVersion': 2,
        'totpEntries': [
          {
            'id': 'a',
            'issuer': 'Alpha',
            'accountName': 'a@a.com',
            'secretBase32': 'AAA',
            'algorithm': 'SHA1',
            'digits': 6,
            'period': 30,
            'createdAt': '2024-01-01T00:00:00.000Z',
          },
          {
            'id': 'b',
            'issuer': 'Beta',
            'accountName': 'b@b.com',
            'secretBase32': 'BBB',
            'algorithm': 'SHA1',
            'digits': 6,
            'period': 30,
            'createdAt': '2024-01-02T00:00:00.000Z',
          },
        ],
        'recoveryCodeSets': [],
        'developerSettings': {'enabled': false},
        'developerEntries': [],
      };

      final result = migrator.migrate(v2Json);
      expect(result.providers, hasLength(2));
      expect(result.providers.map((p) => p.name).toList(), ['Alpha', 'Beta']);
      expect(result.accounts, hasLength(2));
    });

    test('all empty-issuer entries collapse into a single Untitled provider',
        () {
      final v2Json = <String, dynamic>{
        'schemaVersion': 2,
        'totpEntries': [
          {
            'id': 'a',
            'issuer': '',
            'accountName': 'a',
            'secretBase32': 'AAA',
            'algorithm': 'SHA1',
            'digits': 6,
            'period': 30,
            'createdAt': '2024-01-01T00:00:00.000Z',
          },
          {
            'id': 'b',
            'issuer': '   ',
            'accountName': 'b',
            'secretBase32': 'BBB',
            'algorithm': 'SHA1',
            'digits': 6,
            'period': 30,
            'createdAt': '2024-01-02T00:00:00.000Z',
          },
        ],
        'recoveryCodeSets': [],
        'developerSettings': {'enabled': false},
        'developerEntries': [],
      };

      final result = migrator.migrate(v2Json);
      expect(result.providers, hasLength(1));
      expect(result.providers.single.name, 'Untitled');
      expect(result.accounts, hasLength(2));
    });

    test('empty totpEntries list yields no providers', () {
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

    test('v1 input (no schemaVersion) is treated as v2', () {
      final v1Json = <String, dynamic>{
        'totpEntries': [
          {
            'id': 'v1-entry',
            'issuer': 'OldService',
            'accountName': 'user',
            'secretBase32': 'SECRET',
            'algorithm': 'SHA1',
            'digits': 6,
            'period': 30,
            'createdAt': '2023-06-01T00:00:00.000Z',
          },
        ],
        'recoveryCodeSets': [],
        'developerSettings': {'enabled': false},
        'developerEntries': [],
      };
      final result = migrator.migrate(v1Json);
      expect(result.providers.single.name, 'OldService');
    });
  });

  group('VaultMigrator - malformed legacy TotpEntry preservation', () {
    test('preserves secretBase32 verbatim when algorithm is invalid', () {
      final v2Json = <String, dynamic>{
        'schemaVersion': 2,
        'totpEntries': [
          {
            'id': 'malformed-1',
            'issuer': 'BadAlgo Corp',
            'accountName': 'user@badalgo.com',
            'secretBase32': 'JBSWY3DPEHPK3PXP',
            'algorithm': 'INVALID_ALGO',
            'digits': 6,
            'period': 30,
            'createdAt': '2024-05-01T09:00:00.000Z',
          },
        ],
        'recoveryCodeSets': [],
        'developerSettings': {'enabled': false},
        'developerEntries': [],
      };

      final result = migrator.migrate(v2Json);
      expect(result.providers.single.name, 'BadAlgo Corp');
      expect(result.accounts.single.displayName, 'user@badalgo.com');
      final cred = result.accounts.single.credentials.single as TotpCredential;
      expect(cred.id, 'malformed-1');
      expect(cred.secretBase32, 'JBSWY3DPEHPK3PXP');
      expect(cred.algorithm, TotpHashAlgorithm.sha1); // fallback
    });

    test('preserves non-base32 secretBase32 verbatim', () {
      final v2Json = <String, dynamic>{
        'schemaVersion': 2,
        'totpEntries': [
          {
            'id': 'malformed-2',
            'issuer': 'WeirdSecret',
            'accountName': 'test',
            'secretBase32': '!!!not-base32-at-all!!!',
            'algorithm': 'SHA1',
            'digits': 8,
            'period': 60,
            'createdAt': '2024-06-01T00:00:00.000Z',
          },
        ],
        'recoveryCodeSets': [],
        'developerSettings': {'enabled': false},
        'developerEntries': [],
      };
      final result = migrator.migrate(v2Json);
      final cred = result.accounts.single.credentials.single as TotpCredential;
      expect(cred.secretBase32, '!!!not-base32-at-all!!!');
      expect(cred.digits, 8);
      expect(cred.period, 60);
    });

    test('uses fallback defaults when digits/period missing', () {
      final v2Json = <String, dynamic>{
        'schemaVersion': 2,
        'totpEntries': [
          {
            'id': 'malformed-3',
            'issuer': '',
            'accountName': 'minimal',
            'secretBase32': 'MYSECRET',
            'algorithm': 'BOGUS',
            'createdAt': '2024-07-01T00:00:00.000Z',
          },
        ],
        'recoveryCodeSets': [],
        'developerSettings': {'enabled': false},
        'developerEntries': [],
      };
      final result = migrator.migrate(v2Json);
      final cred = result.accounts.single.credentials.single as TotpCredential;
      expect(cred.secretBase32, 'MYSECRET');
      expect(cred.algorithm, TotpHashAlgorithm.sha1);
      expect(cred.digits, 6);
      expect(cred.period, 30);
    });

    test('handles entry with missing id and createdAt gracefully', () {
      final v2Json = <String, dynamic>{
        'schemaVersion': 2,
        'totpEntries': [
          {
            'issuer': 'NoId Service',
            'accountName': 'user',
            'secretBase32': 'PRESERVETHIS',
            'algorithm': 'SHA256',
            'digits': 6,
            'period': 30,
          },
        ],
        'recoveryCodeSets': [],
        'developerSettings': {'enabled': false},
        'developerEntries': [],
      };
      final result = migrator.migrate(v2Json);
      final cred = result.accounts.single.credentials.single as TotpCredential;
      expect(cred.secretBase32, 'PRESERVETHIS');
      expect(cred.algorithm, TotpHashAlgorithm.sha256);
    });

    test('malformed entry does not affect migration of other valid entries',
        () {
      final v2Json = <String, dynamic>{
        'schemaVersion': 2,
        'totpEntries': [
          {
            'id': 'good-1',
            'issuer': 'GoodService',
            'accountName': 'good@example.com',
            'secretBase32': 'GOODSECRET',
            'algorithm': 'SHA1',
            'digits': 6,
            'period': 30,
            'createdAt': '2024-01-01T00:00:00.000Z',
          },
          {
            'id': 'bad-1',
            'issuer': 'BadService',
            'accountName': 'bad@example.com',
            'secretBase32': 'BADSECRET',
            'algorithm': 'NOT_A_REAL_ALGO',
            'digits': 6,
            'period': 30,
            'createdAt': '2024-02-01T00:00:00.000Z',
          },
          {
            'id': 'good-2',
            'issuer': 'AnotherGood',
            'accountName': 'another@example.com',
            'secretBase32': 'ANOTHERSECRET',
            'algorithm': 'SHA512',
            'digits': 8,
            'period': 60,
            'createdAt': '2024-03-01T00:00:00.000Z',
          },
        ],
        'recoveryCodeSets': [],
        'developerSettings': {'enabled': false},
        'developerEntries': [],
      };

      final result = migrator.migrate(v2Json);
      expect(result.providers, hasLength(3));
      expect(result.accounts, hasLength(3));
      expect(
        result.providers.map((p) => p.name).toList(),
        ['GoodService', 'BadService', 'AnotherGood'],
      );
      // All three secrets preserved in order.
      final secrets = result.accounts
          .map((a) => (a.credentials.single as TotpCredential).secretBase32)
          .toList();
      expect(secrets, ['GOODSECRET', 'BADSECRET', 'ANOTHERSECRET']);
    });
  });
}
