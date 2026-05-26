import 'package:uuid/uuid.dart';

import 'vault_models.dart';
import 'vault_repository.dart' show VaultFormatException;

/// A pure migrator that takes raw decrypted JSON of any supported schema
/// version and returns a [VaultData] at the current schema version.
///
/// Pure: no file IO, no logging of secret material, no global clock reads
/// beyond what the migration algorithm requires.
///
/// Dispatch chain:
///   - schemaVersion 1 or 2 → legacy-conversion path (v2 → v3)
///   - schemaVersion 3      → identity (parse via [VaultData.fromJson])
///   - schemaVersion > 3    → throws [VaultFormatException]
class VaultMigrator {
  const VaultMigrator();

  VaultData migrate(Map<String, dynamic> rawJson) {
    final schemaVersion = (rawJson['schemaVersion'] as int?) ?? 1;

    if (schemaVersion > vaultDataSchemaVersion) {
      throw VaultFormatException(
        'Vault was created by a newer app version (schemaVersion = $schemaVersion).',
      );
    }

    if (schemaVersion <= 2) {
      return _migrateFromV2(rawJson);
    }

    return VaultData.fromJson(rawJson);
  }

  /// Converts a v1 or v2 JSON payload to a v3 [VaultData].
  ///
  /// Migration rules:
  ///   - TOTP entries are bucketed by case-insensitive trimmed `issuer`. All
  ///     entries with the same normalized issuer become accounts under a
  ///     single ServiceProvider whose `name` is the first non-empty issuer
  ///     string seen for that bucket. Entries with empty issuer collapse
  ///     into a single "Untitled" provider.
  ///   - Each legacy `RecoveryCodeSet` becomes its own ServiceProvider whose
  ///     `name` is the set's title (or "Recovery codes" when empty), holding
  ///     one Account whose `displayName` is the same fallback string. The
  ///     user can later move the account under any provider via the UI.
  ///   - Account ordering: TOTP-derived accounts appear in the original
  ///     `totpEntries` order, followed by RecoveryCodeSet-derived accounts
  ///     in their original order.
  ///   - ServiceProvider ordering: matches first-occurrence order across
  ///     the combined account stream (TOTP first, then recovery).
  ///   - Secret bytes are preserved verbatim even when other fields are
  ///     malformed (rendering errors are surfaced per-credential at the UI;
  ///     migration must never drop data).
  VaultData _migrateFromV2(Map<String, dynamic> rawJson) {
    const uuid = Uuid();
    final providers = <ServiceProvider>[];
    final accounts = <Account>[];

    String normalizeBucketKey(String issuer) =>
        issuer.trim().toLowerCase();

    // Map: bucket key → providerId.
    final providerByBucket = <String, String>{};

    ServiceProvider ensureProvider({
      required String bucketKey,
      required String displayName,
      required DateTime createdAt,
    }) {
      final existingId = providerByBucket[bucketKey];
      if (existingId != null) {
        return providers.firstWhere((p) => p.id == existingId);
      }
      final p = ServiceProvider(
        id: uuid.v4(),
        name: displayName,
        createdAt: createdAt,
        updatedAt: createdAt,
      );
      providers.add(p);
      providerByBucket[bucketKey] = p.id;
      return p;
    }

    // --- TOTP entries -> accounts grouped by issuer bucket ---
    final totpEntriesAny = rawJson['totpEntries'];
    if (totpEntriesAny is List) {
      for (final entryJson in totpEntriesAny) {
        if (entryJson is! Map) continue;
        final map = Map<String, dynamic>.from(entryJson);

        // Parse with safe fallbacks to never lose secret bytes.
        final id = map['id'] as String? ?? uuid.v4();
        final issuer = (map['issuer'] as String? ?? '').trim();
        final accountName = (map['accountName'] as String? ?? '').trim();
        final secretBase32 = map['secretBase32'] as String? ?? '';
        final createdAtStr = map['createdAt'] as String?;
        final createdAt = (createdAtStr != null
                ? DateTime.tryParse(createdAtStr)
                : null) ??
            DateTime.now();
        final digits = (map['digits'] is int) ? map['digits'] as int : 6;
        final period = (map['period'] is int) ? map['period'] as int : 30;

        TotpHashAlgorithm algorithm;
        try {
          algorithm = TotpHashAlgorithmX.fromOtpauthName(
            map['algorithm'] as String? ?? 'SHA1',
          );
        } catch (_) {
          algorithm = TotpHashAlgorithm.sha1;
        }

        // ServiceProvider bucket: empty issuer collapses to "Untitled".
        final bucketKey = issuer.isEmpty ? '' : normalizeBucketKey(issuer);
        final providerName = issuer.isEmpty ? 'Untitled' : issuer;
        final provider = ensureProvider(
          bucketKey: bucketKey,
          displayName: providerName,
          createdAt: createdAt,
        );

        // displayName for the account: prefer accountName, else fall back to
        // the issuer (so single-account providers still read sensibly),
        // else "Account".
        final displayName = accountName.isNotEmpty
            ? accountName
            : (issuer.isNotEmpty ? issuer : 'Account');

        accounts.add(
          Account(
            id: uuid.v4(),
            providerId: provider.id,
            displayName: displayName,
            createdAt: createdAt,
            updatedAt: createdAt,
            credentials: [
              TotpCredential(
                id: id,
                createdAt: createdAt,
                secretBase32: secretBase32,
                algorithm: algorithm,
                digits: digits,
                period: period,
              ),
            ],
          ),
        );
      }
    }

    // --- RecoveryCodeSets -> their own ServiceProvider + Account ---
    final recoveryCodeSetsAny = rawJson['recoveryCodeSets'];
    if (recoveryCodeSetsAny is List) {
      for (final entryJson in recoveryCodeSetsAny) {
        if (entryJson is! Map) continue;
        final map = Map<String, dynamic>.from(entryJson);
        final legacy = RecoveryCodeSet.fromJson(map);

        final fallbackName = legacy.title.trim().isNotEmpty
            ? legacy.title.trim()
            : 'Recovery codes';

        // Each recovery set gets its own ServiceProvider so the user can
        // later move the account elsewhere without merging surprises.
        final provider = ServiceProvider(
          id: uuid.v4(),
          name: fallbackName,
          createdAt: legacy.createdAt,
          updatedAt: legacy.createdAt,
        );
        providers.add(provider);

        accounts.add(
          Account(
            id: uuid.v4(),
            providerId: provider.id,
            displayName: fallbackName,
            createdAt: legacy.createdAt,
            updatedAt: legacy.createdAt,
            credentials: [
              RecoveryCodesCredential(
                id: legacy.id,
                createdAt: legacy.createdAt,
                codes: legacy.codes,
              ),
            ],
          ),
        );
      }
    }

    // --- Pass through developer settings and entries unchanged ---
    final developerSettingsAny = rawJson['developerSettings'];
    final developerSettings = developerSettingsAny is Map
        ? DeveloperSettings.fromJson(
            Map<String, dynamic>.from(developerSettingsAny),
          )
        : DeveloperSettings.disabled();

    final developerEntriesAny = rawJson['developerEntries'];
    final developerEntries = (developerEntriesAny is List)
        ? developerEntriesAny
              .whereType<Map>()
              .map(
                (e) => DeveloperEntry.fromJson(Map<String, dynamic>.from(e)),
              )
              .toList()
        : <DeveloperEntry>[];

    return VaultData(
      schemaVersion: vaultDataSchemaVersion,
      providers: providers,
      accounts: accounts,
      developerSettings: developerSettings,
      developerEntries: developerEntries,
    );
  }
}
