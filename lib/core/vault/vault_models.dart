const int vaultDataSchemaVersion = 1;

enum TotpHashAlgorithm { sha1, sha256, sha512 }

extension TotpHashAlgorithmX on TotpHashAlgorithm {
  String get otpauthName => switch (this) {
    TotpHashAlgorithm.sha1 => 'SHA1',
    TotpHashAlgorithm.sha256 => 'SHA256',
    TotpHashAlgorithm.sha512 => 'SHA512',
  };

  static TotpHashAlgorithm fromOtpauthName(String name) {
    final n = name.trim().toUpperCase();
    return switch (n) {
      'SHA1' => TotpHashAlgorithm.sha1,
      'SHA256' => TotpHashAlgorithm.sha256,
      'SHA512' => TotpHashAlgorithm.sha512,
      _ => throw FormatException('Unsupported TOTP hash algorithm: $name'),
    };
  }
}

class TotpEntry {
  final String id;
  final String issuer;
  final String accountName;
  final String secretBase32;
  final TotpHashAlgorithm algorithm;
  final int digits;
  final int period;
  final DateTime createdAt;

  const TotpEntry({
    required this.id,
    required this.issuer,
    required this.accountName,
    required this.secretBase32,
    required this.algorithm,
    required this.digits,
    required this.period,
    required this.createdAt,
  });

  TotpEntry copyWith({
    String? issuer,
    String? accountName,
    String? secretBase32,
    TotpHashAlgorithm? algorithm,
    int? digits,
    int? period,
  }) {
    return TotpEntry(
      id: id,
      issuer: issuer ?? this.issuer,
      accountName: accountName ?? this.accountName,
      secretBase32: secretBase32 ?? this.secretBase32,
      algorithm: algorithm ?? this.algorithm,
      digits: digits ?? this.digits,
      period: period ?? this.period,
      createdAt: createdAt,
    );
  }

  Map<String, dynamic> toJson() => <String, dynamic>{
    'id': id,
    'issuer': issuer,
    'accountName': accountName,
    'secretBase32': secretBase32,
    'algorithm': algorithm.otpauthName,
    'digits': digits,
    'period': period,
    'createdAt': createdAt.toIso8601String(),
  };

  factory TotpEntry.fromJson(Map<String, dynamic> json) {
    final id = json['id'] as String?;
    final issuer = json['issuer'] as String? ?? '';
    final accountName = json['accountName'] as String? ?? '';
    final secretBase32 = json['secretBase32'] as String?;
    final algorithmStr = json['algorithm'] as String? ?? 'SHA1';
    final digits = json['digits'] as int? ?? 6;
    final period = json['period'] as int? ?? 30;
    final createdAtStr = json['createdAt'] as String?;

    if (id == null || secretBase32 == null || createdAtStr == null) {
      throw FormatException('Invalid TOTP entry');
    }

    return TotpEntry(
      id: id,
      issuer: issuer,
      accountName: accountName,
      secretBase32: secretBase32,
      algorithm: TotpHashAlgorithmX.fromOtpauthName(algorithmStr),
      digits: digits,
      period: period,
      createdAt: DateTime.parse(createdAtStr),
    );
  }
}

class RecoveryCodeSet {
  final String id;
  final String title;
  final List<String> codes;
  final DateTime createdAt;

  const RecoveryCodeSet({
    required this.id,
    required this.title,
    required this.codes,
    required this.createdAt,
  });

  Map<String, dynamic> toJson() => <String, dynamic>{
    'id': id,
    'title': title,
    'codes': codes,
    'createdAt': createdAt.toIso8601String(),
  };

  factory RecoveryCodeSet.fromJson(Map<String, dynamic> json) {
    final id = json['id'] as String?;
    final title = json['title'] as String? ?? '';
    final codesAny = json['codes'];
    final createdAtStr = json['createdAt'] as String?;

    if (id == null || createdAtStr == null) {
      throw FormatException('Invalid recovery code set');
    }

    final codes = (codesAny is List)
        ? codesAny.map((e) => e.toString()).toList(growable: false)
        : <String>[];
    return RecoveryCodeSet(
      id: id,
      title: title,
      codes: codes,
      createdAt: DateTime.parse(createdAtStr),
    );
  }
}

class VaultData {
  final int schemaVersion;
  final List<TotpEntry> totpEntries;
  final List<RecoveryCodeSet> recoveryCodeSets;

  const VaultData({
    required this.schemaVersion,
    required this.totpEntries,
    required this.recoveryCodeSets,
  });

  factory VaultData.empty() => const VaultData(
    schemaVersion: vaultDataSchemaVersion,
    totpEntries: <TotpEntry>[],
    recoveryCodeSets: <RecoveryCodeSet>[],
  );

  VaultData copyWith({
    List<TotpEntry>? totpEntries,
    List<RecoveryCodeSet>? recoveryCodeSets,
  }) {
    return VaultData(
      schemaVersion: schemaVersion,
      totpEntries: List.unmodifiable(totpEntries ?? this.totpEntries),
      recoveryCodeSets: List.unmodifiable(
        recoveryCodeSets ?? this.recoveryCodeSets,
      ),
    );
  }

  Map<String, dynamic> toJson() => <String, dynamic>{
    'schemaVersion': schemaVersion,
    'totpEntries': totpEntries.map((e) => e.toJson()).toList(growable: false),
    'recoveryCodeSets': recoveryCodeSets
        .map((e) => e.toJson())
        .toList(growable: false),
  };

  factory VaultData.fromJson(Map<String, dynamic> json) {
    final schemaVersion = json['schemaVersion'] as int? ?? 1;

    final totpsAny = json['totpEntries'];
    final recAny = json['recoveryCodeSets'];

    final totps = (totpsAny is List)
        ? totpsAny
              .whereType<Map>()
              .map((e) => TotpEntry.fromJson(Map<String, dynamic>.from(e)))
              .toList(growable: false)
        : <TotpEntry>[];

    final recs = (recAny is List)
        ? recAny
              .whereType<Map>()
              .map(
                (e) => RecoveryCodeSet.fromJson(Map<String, dynamic>.from(e)),
              )
              .toList(growable: false)
        : <RecoveryCodeSet>[];

    return VaultData(
      schemaVersion: schemaVersion,
      totpEntries: List.unmodifiable(totps),
      recoveryCodeSets: List.unmodifiable(recs),
    );
  }
}
