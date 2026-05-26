import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:rescue_auth_kit/core/vault/vault_models.dart';

// ---------------------------------------------------------------------------
// Property-based tests for VaultDataOps (provider + account + credential).
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

String _randomUuid(Random rng) {
  const hex = '0123456789abcdef';
  String segment(int len) => String.fromCharCodes(
        List.generate(len, (_) => hex.codeUnitAt(rng.nextInt(16))),
      );
  return '${segment(8)}-${segment(4)}-${segment(4)}-${segment(4)}-${segment(12)}';
}

DateTime _randomDateTime(Random rng) {
  final startSec = DateTime.utc(2020).millisecondsSinceEpoch ~/ 1000;
  final endSec = DateTime.utc(2030).millisecondsSinceEpoch ~/ 1000;
  final sec = startSec + rng.nextInt(endSec - startSec);
  return DateTime.fromMillisecondsSinceEpoch(sec * 1000, isUtc: true);
}

TotpCredential _genTotpCredential(Random rng) {
  return TotpCredential(
    id: _randomUuid(rng),
    createdAt: _randomDateTime(rng),
    secretBase32: _randomString(rng, 8, 32, chars: _base32Chars),
    algorithm: TotpHashAlgorithm
        .values[rng.nextInt(TotpHashAlgorithm.values.length)],
    digits: 6 + rng.nextInt(5),
    period: 15 + rng.nextInt(106),
  );
}

RecoveryCodesCredential _genRecoveryCodesCredential(Random rng) {
  final codeCount = rng.nextInt(17);
  final codes = List.generate(codeCount, (_) => _randomString(rng, 4, 16));
  return RecoveryCodesCredential(
    id: _randomUuid(rng),
    createdAt: _randomDateTime(rng),
    codes: codes,
  );
}

Credential _genCredential(Random rng) =>
    rng.nextBool() ? _genTotpCredential(rng) : _genRecoveryCodesCredential(rng);

ServiceProvider _genProvider(Random rng) {
  final createdAt = _randomDateTime(rng);
  return ServiceProvider(
    id: _randomUuid(rng),
    name: _randomString(rng, 1, 30),
    createdAt: createdAt,
    updatedAt: createdAt,
  );
}

Account _genAccount(Random rng, String providerId, {int credCount = -1}) {
  final cc = credCount < 0 ? rng.nextInt(5) : credCount;
  final credentials = List.generate(cc, (_) => _genCredential(rng));
  final createdAt = _randomDateTime(rng);
  return Account(
    id: _randomUuid(rng),
    providerId: providerId,
    displayName: _randomString(rng, 1, 30),
    createdAt: createdAt,
    updatedAt: createdAt,
    credentials: credentials,
  );
}

VaultData _genVault(Random rng,
    {int providerCount = 2, int accountsPerProvider = 2}) {
  final providers =
      List.generate(providerCount, (_) => _genProvider(rng));
  final accounts = <Account>[];
  for (final p in providers) {
    for (int i = 0; i < accountsPerProvider; i++) {
      accounts.add(_genAccount(rng, p.id));
    }
  }
  return VaultData(
    schemaVersion: vaultDataSchemaVersion,
    providers: providers,
    accounts: accounts,
    developerSettings: DeveloperSettings.disabled(),
    developerEntries: const <DeveloperEntry>[],
  );
}

void main() {
  group('Property 8: withCredential length law', () {
    test('grows target account by one and leaves others alone', () {
      final rng = Random(0xC0DE);
      for (int i = 0; i < 50; i++) {
        final v = _genVault(rng,
            providerCount: 1 + rng.nextInt(3),
            accountsPerProvider: 1 + rng.nextInt(3));
        final targetIndex = rng.nextInt(v.accounts.length);
        final targetId = v.accounts[targetIndex].id;
        final draft = _genCredential(rng);
        final now = _randomDateTime(rng);

        final beforeLengths =
            v.accounts.map((a) => a.credentials.length).toList();
        final after = v.withCredential(targetId, draft, now: now);

        expect(after.accounts.length, v.accounts.length);
        for (int j = 0; j < v.accounts.length; j++) {
          if (j == targetIndex) {
            expect(after.accounts[j].credentials.length,
                beforeLengths[j] + 1);
            expect(after.accounts[j].credentials.last, equals(draft));
            expect(after.accounts[j].updatedAt, now);
          } else {
            expect(after.accounts[j], equals(v.accounts[j]));
          }
        }
      }
    });
  });

  group('Property 9: add+remove is identity', () {
    test('round-trip leaves credentials list intact', () {
      final rng = Random(0xBEEF);
      for (int i = 0; i < 50; i++) {
        final v = _genVault(rng);
        final targetIndex = rng.nextInt(v.accounts.length);
        final targetId = v.accounts[targetIndex].id;
        final draft = _genCredential(rng);
        final t1 = _randomDateTime(rng);
        final t2 = _randomDateTime(rng);

        final added = v.withCredential(targetId, draft, now: t1);
        final removed =
            added.withoutCredential(targetId, draft.id, now: t2);

        expect(removed.accounts[targetIndex].credentials,
            orderedEquals(v.accounts[targetIndex].credentials));
      }
    });
  });

  group('Property 10: emptied account stays in place', () {
    test('removing the last credential keeps the account', () {
      final rng = Random(0xDEAD);
      for (int i = 0; i < 30; i++) {
        final draft = _genCredential(rng);
        final provider = _genProvider(rng);
        final account = _genAccount(rng, provider.id, credCount: 0)
            .copyWith(credentials: [draft]);
        final v = VaultData(
          schemaVersion: vaultDataSchemaVersion,
          providers: [provider],
          accounts: [account],
          developerSettings: DeveloperSettings.disabled(),
          developerEntries: const <DeveloperEntry>[],
        );

        final after = v.withoutCredential(account.id, draft.id,
            now: _randomDateTime(rng));
        expect(after.accounts.single.id, account.id);
        expect(after.accounts.single.credentials, isEmpty);
      }
    });
  });

  group('withRenamedAccount only updates displayName + updatedAt', () {
    test('credentials and createdAt stay intact', () {
      final rng = Random(0xCAFE);
      for (int i = 0; i < 30; i++) {
        final v = _genVault(rng);
        final idx = rng.nextInt(v.accounts.length);
        final original = v.accounts[idx];
        final newName = _randomString(rng, 1, 25);
        final now = _randomDateTime(rng);

        final after = v.withRenamedAccount(
          original.id,
          displayName: newName,
          now: now,
        );

        final renamed = after.accounts[idx];
        expect(renamed.id, original.id);
        expect(renamed.providerId, original.providerId);
        expect(renamed.createdAt, original.createdAt);
        expect(renamed.credentials, orderedEquals(original.credentials));
        expect(renamed.displayName, newName);
        expect(renamed.updatedAt, now);
      }
    });
  });

  group('withRenamedProvider only updates name + updatedAt', () {
    test('createdAt and id stay intact', () {
      final rng = Random(0xFADE);
      for (int i = 0; i < 30; i++) {
        final v = _genVault(rng);
        final pIdx = rng.nextInt(v.providers.length);
        final original = v.providers[pIdx];
        final newName = _randomString(rng, 1, 30);
        final now = _randomDateTime(rng);

        final after = v.withRenamedProvider(original.id,
            name: newName, now: now);
        final renamed = after.providers[pIdx];
        expect(renamed.id, original.id);
        expect(renamed.createdAt, original.createdAt);
        expect(renamed.name, newName);
        expect(renamed.updatedAt, now);
      }
    });
  });

  group('withoutProvider cascades to accounts', () {
    test('all accounts under the removed provider disappear', () {
      final rng = Random(0xFACE);
      final v = _genVault(rng, providerCount: 3, accountsPerProvider: 2);
      final removeId = v.providers[1].id;
      final after = v.withoutProvider(removeId);
      expect(after.providers, hasLength(2));
      expect(after.providers.any((p) => p.id == removeId), isFalse);
      // No accounts referencing the removed provider.
      expect(after.accounts.any((a) => a.providerId == removeId), isFalse);
      // Other providers' accounts kept.
      expect(after.accounts, hasLength(4));
    });
  });

  group('withMovedAccount changes providerId only', () {
    test('credentials and other accounts unchanged', () {
      final rng = Random(0xBABE);
      final v = _genVault(rng, providerCount: 2, accountsPerProvider: 2);
      final account = v.accounts.first;
      final newProviderId =
          v.providers.firstWhere((p) => p.id != account.providerId).id;
      final now = _randomDateTime(rng);

      final after = v.withMovedAccount(
        account.id,
        newProviderId: newProviderId,
        now: now,
      );

      final moved = after.accounts.firstWhere((a) => a.id == account.id);
      expect(moved.providerId, newProviderId);
      expect(moved.credentials, orderedEquals(account.credentials));
      expect(moved.updatedAt, now);

      // Other accounts unchanged.
      for (final a in v.accounts.skip(1)) {
        expect(after.accounts.firstWhere((x) => x.id == a.id), equals(a));
      }
    });
  });

  group('Unknown id error surfaces', () {
    test('requireProvider throws on unknown id', () {
      final v = VaultData.empty();
      expect(() => v.requireProvider('nope'),
          throwsA(isA<ProviderNotFoundError>()));
    });

    test('withoutProvider throws on unknown id', () {
      final v = VaultData.empty();
      expect(() => v.withoutProvider('nope'),
          throwsA(isA<ProviderNotFoundError>()));
    });

    test('withRenamedProvider throws on unknown id', () {
      final v = VaultData.empty();
      expect(
        () => v.withRenamedProvider('nope',
            name: 'X', now: DateTime.utc(2026)),
        throwsA(isA<ProviderNotFoundError>()),
      );
    });

    test('requireAccount throws on unknown id', () {
      final v = VaultData.empty();
      expect(() => v.requireAccount('nope'),
          throwsA(isA<AccountNotFoundError>()));
    });

    test('withoutAccount throws on unknown id', () {
      final v = VaultData.empty();
      expect(() => v.withoutAccount('nope'),
          throwsA(isA<AccountNotFoundError>()));
    });

    test('withRenamedAccount throws on unknown id', () {
      final v = VaultData.empty();
      expect(
        () => v.withRenamedAccount('nope',
            displayName: 'X', now: DateTime.utc(2026)),
        throwsA(isA<AccountNotFoundError>()),
      );
    });

    test('withCredential throws on unknown account', () {
      final v = VaultData.empty();
      expect(
        () => v.withCredential(
          'nope',
          TotpCredential(
            id: 't1',
            createdAt: DateTime.utc(2026),
            secretBase32: 'JBSWY3DPEHPK3PXP',
            algorithm: TotpHashAlgorithm.sha1,
            digits: 6,
            period: 30,
          ),
          now: DateTime.utc(2026),
        ),
        throwsA(isA<AccountNotFoundError>()),
      );
    });

    test('withoutCredential throws on unknown credential', () {
      final p = ServiceProvider(
        id: 'p1',
        name: 'P',
        createdAt: DateTime.utc(2026),
        updatedAt: DateTime.utc(2026),
      );
      final account = Account(
        id: 'a1',
        providerId: p.id,
        displayName: 'A',
        createdAt: DateTime.utc(2026),
        updatedAt: DateTime.utc(2026),
        credentials: const [],
      );
      final v = VaultData(
        schemaVersion: vaultDataSchemaVersion,
        providers: [p],
        accounts: [account],
        developerSettings: DeveloperSettings.disabled(),
        developerEntries: const <DeveloperEntry>[],
      );
      expect(
        () => v.withoutCredential('a1', 'missing', now: DateTime.utc(2026)),
        throwsA(isA<CredentialNotFoundError>()),
      );
    });

    test('withNewAccount throws on unknown providerId', () {
      final v = VaultData.empty();
      final account = Account(
        id: 'a1',
        providerId: 'unknown',
        displayName: 'A',
        createdAt: DateTime.utc(2026),
        updatedAt: DateTime.utc(2026),
        credentials: const [],
      );
      expect(() => v.withNewAccount(account),
          throwsA(isA<ProviderNotFoundError>()));
    });
  });

  group('withNewProvider appends', () {
    test('appends to the end', () {
      final v = VaultData.empty();
      final p = ServiceProvider(
        id: 'p1',
        name: 'P',
        createdAt: DateTime.utc(2026),
        updatedAt: DateTime.utc(2026),
      );
      final after = v.withNewProvider(p);
      expect(after.providers, hasLength(1));
      expect(after.providers.single.id, 'p1');
    });
  });

  _additionalCredentialOpTests();
}


// ---------------------------------------------------------------------------
// withReplacedCredential / withMovedCredential
// ---------------------------------------------------------------------------

void _additionalCredentialOpTests() {
  group('withReplacedCredential', () {
    test('replaces credential in place and bumps updatedAt', () {
      final p = ServiceProvider(
        id: 'p',
        name: 'P',
        createdAt: DateTime.utc(2026),
        updatedAt: DateTime.utc(2026),
      );
      final c1 = TotpCredential(
        id: 't1',
        createdAt: DateTime.utc(2026),
        secretBase32: 'AAA',
        algorithm: TotpHashAlgorithm.sha1,
        digits: 6,
        period: 30,
      );
      final c2 = RecoveryCodesCredential(
        id: 'r1',
        createdAt: DateTime.utc(2026),
        codes: const ['x'],
      );
      final account = Account(
        id: 'a',
        providerId: 'p',
        displayName: 'A',
        createdAt: DateTime.utc(2026),
        updatedAt: DateTime.utc(2026),
        credentials: [c1, c2],
      );
      final v = VaultData(
        schemaVersion: vaultDataSchemaVersion,
        providers: [p],
        accounts: [account],
        developerSettings: DeveloperSettings.disabled(),
        developerEntries: const <DeveloperEntry>[],
      );

      final replacement = c2.copyWith(codes: const ['x', 'y', 'z']);
      final after = v.withReplacedCredential(
        'a',
        'r1',
        replacement,
        now: DateTime.utc(2027),
      );

      // c1 unchanged, c2 replaced.
      expect(after.accounts.single.credentials[0], equals(c1));
      expect(after.accounts.single.credentials[1], equals(replacement));
      // Position preserved.
      expect(after.accounts.single.credentials.length, 2);
      // updatedAt bumped.
      expect(after.accounts.single.updatedAt, DateTime.utc(2027));
    });

    test('throws when replacement.id != credentialId', () {
      final account = Account(
        id: 'a',
        providerId: 'p',
        displayName: 'A',
        createdAt: DateTime.utc(2026),
        updatedAt: DateTime.utc(2026),
        credentials: [
          TotpCredential(
            id: 't1',
            createdAt: DateTime.utc(2026),
            secretBase32: 'AAA',
            algorithm: TotpHashAlgorithm.sha1,
            digits: 6,
            period: 30,
          ),
        ],
      );
      final v = VaultData(
        schemaVersion: vaultDataSchemaVersion,
        providers: [
          ServiceProvider(
            id: 'p',
            name: 'P',
            createdAt: DateTime.utc(2026),
            updatedAt: DateTime.utc(2026),
          ),
        ],
        accounts: [account],
        developerSettings: DeveloperSettings.disabled(),
        developerEntries: const <DeveloperEntry>[],
      );

      final wrong = TotpCredential(
        id: 'OTHER',
        createdAt: DateTime.utc(2026),
        secretBase32: 'BBB',
        algorithm: TotpHashAlgorithm.sha1,
        digits: 6,
        period: 30,
      );
      expect(
        () => v.withReplacedCredential(
          'a',
          't1',
          wrong,
          now: DateTime.utc(2027),
        ),
        throwsA(isA<StateError>()),
      );
    });

    test('throws on unknown account / credential id', () {
      final v = VaultData.empty();
      expect(
        () => v.withReplacedCredential(
          'nope',
          't',
          TotpCredential(
            id: 't',
            createdAt: DateTime.utc(2026),
            secretBase32: 'A',
            algorithm: TotpHashAlgorithm.sha1,
            digits: 6,
            period: 30,
          ),
          now: DateTime.utc(2027),
        ),
        throwsA(isA<AccountNotFoundError>()),
      );
    });
  });

  group('withMovedCredential', () {
    VaultData twoAccountsOneCred() {
      final p = ServiceProvider(
        id: 'p',
        name: 'P',
        createdAt: DateTime.utc(2026),
        updatedAt: DateTime.utc(2026),
      );
      final cred = RecoveryCodesCredential(
        id: 'r1',
        createdAt: DateTime.utc(2026),
        codes: const ['a', 'b'],
      );
      final aFrom = Account(
        id: 'from',
        providerId: 'p',
        displayName: 'From',
        createdAt: DateTime.utc(2026),
        updatedAt: DateTime.utc(2026),
        credentials: [cred],
      );
      final aTo = Account(
        id: 'to',
        providerId: 'p',
        displayName: 'To',
        createdAt: DateTime.utc(2026),
        updatedAt: DateTime.utc(2026),
        credentials: const [],
      );
      return VaultData(
        schemaVersion: vaultDataSchemaVersion,
        providers: [p],
        accounts: [aFrom, aTo],
        developerSettings: DeveloperSettings.disabled(),
        developerEntries: const <DeveloperEntry>[],
      );
    }

    test('moves credential, preserves id/createdAt/contents', () {
      final v = twoAccountsOneCred();
      final original = v.accounts.first.credentials.single;
      final after = v.withMovedCredential(
        'from',
        'r1',
        'to',
        now: DateTime.utc(2027),
      );
      expect(after.requireAccount('from').credentials, isEmpty);
      expect(after.requireAccount('to').credentials.single, equals(original));
      // Both accounts updatedAt bumped.
      expect(after.requireAccount('from').updatedAt, DateTime.utc(2027));
      expect(after.requireAccount('to').updatedAt, DateTime.utc(2027));
    });

    test('no-op when from == to', () {
      final v = twoAccountsOneCred();
      final after = v.withMovedCredential(
        'from',
        'r1',
        'from',
        now: DateTime.utc(2027),
      );
      expect(after, equals(v));
    });

    test('throws on unknown destination account', () {
      final v = twoAccountsOneCred();
      expect(
        () => v.withMovedCredential(
          'from',
          'r1',
          'unknown',
          now: DateTime.utc(2027),
        ),
        throwsA(isA<AccountNotFoundError>()),
      );
    });

    test('throws when credential not in source account', () {
      final v = twoAccountsOneCred();
      expect(
        () => v.withMovedCredential(
          'to',
          'r1',
          'from',
          now: DateTime.utc(2027),
        ),
        throwsA(isA<CredentialNotFoundError>()),
      );
    });
  });

  group('withMergedAccount', () {
    VaultData buildVault() {
      final p1 = ServiceProvider(
        id: 'p1',
        name: 'Google',
        createdAt: DateTime.utc(2026),
        updatedAt: DateTime.utc(2026),
      );
      final p2 = ServiceProvider(
        id: 'p2',
        name: 'Other',
        createdAt: DateTime.utc(2026),
        updatedAt: DateTime.utc(2026),
      );
      final c1 = TotpCredential(
        id: 't1',
        createdAt: DateTime.utc(2026),
        secretBase32: 'AAA',
        algorithm: TotpHashAlgorithm.sha1,
        digits: 6,
        period: 30,
      );
      final c2 = RecoveryCodesCredential(
        id: 'r1',
        createdAt: DateTime.utc(2026),
        codes: const ['one', 'two'],
      );
      final c3 = RecoveryCodesCredential(
        id: 'r2',
        createdAt: DateTime.utc(2026),
        codes: const ['three'],
      );
      final source = Account(
        id: 'src',
        providerId: 'p2',
        displayName: 'me@gmail.com',
        createdAt: DateTime.utc(2026),
        updatedAt: DateTime.utc(2026),
        credentials: [c2, c3],
      );
      final target = Account(
        id: 'tgt',
        providerId: 'p1',
        displayName: 'me@gmail.com',
        createdAt: DateTime.utc(2026),
        updatedAt: DateTime.utc(2026),
        credentials: [c1],
      );
      return VaultData(
        schemaVersion: vaultDataSchemaVersion,
        providers: [p1, p2],
        accounts: [source, target],
        developerSettings: DeveloperSettings.disabled(),
        developerEntries: const <DeveloperEntry>[],
      );
    }

    test('appends source credentials to target and deletes source', () {
      final v = buildVault();
      final after = v.withMergedAccount(
        'src',
        'tgt',
        now: DateTime.utc(2027),
      );

      // Source is gone.
      expect(after.accounts.any((a) => a.id == 'src'), isFalse);
      // Target preserved with merged credentials.
      final t = after.requireAccount('tgt');
      expect(t.providerId, 'p1');
      expect(t.displayName, 'me@gmail.com');
      expect(t.createdAt, DateTime.utc(2026));
      expect(t.updatedAt, DateTime.utc(2027));
      expect(t.credentials.map((c) => c.id).toList(), ['t1', 'r1', 'r2']);
    });

    test('throws on unknown source/target', () {
      final v = buildVault();
      expect(
        () => v.withMergedAccount('nope', 'tgt', now: DateTime.utc(2027)),
        throwsA(isA<AccountNotFoundError>()),
      );
      expect(
        () => v.withMergedAccount('src', 'nope', now: DateTime.utc(2027)),
        throwsA(isA<AccountNotFoundError>()),
      );
    });

    test('throws when source == target', () {
      final v = buildVault();
      expect(
        () => v.withMergedAccount('src', 'src', now: DateTime.utc(2027)),
        throwsA(isA<StateError>()),
      );
    });
  });
}
