import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:cryptography/cryptography.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import '../crypto/vault_crypto.dart';
import 'vault_models.dart';

class VaultAuthException implements Exception {
  const VaultAuthException();
  @override
  String toString() => 'VaultAuthException: wrong password or corrupted vault';
}

class VaultFormatException implements Exception {
  final String message;
  const VaultFormatException(this.message);
  @override
  String toString() => 'VaultFormatException: $message';
}

class VaultIoException implements Exception {
  final String message;
  const VaultIoException(this.message);
  @override
  String toString() => 'VaultIoException: $message';
}

class VaultHandle {
  final VaultData data;
  final SecretKey key;
  final VaultKdfParams kdfParams;
  final String cipher;

  const VaultHandle({
    required this.data,
    required this.key,
    required this.kdfParams,
    required this.cipher,
  });

  VaultHandle copyWith({VaultData? data}) {
    return VaultHandle(
      data: data ?? this.data,
      key: key,
      kdfParams: kdfParams,
      cipher: cipher,
    );
  }
}

class VaultRepository {
  final String vaultFilePath;
  final VaultCrypto crypto;

  static const String vaultFileName = 'vault.rekvault';

  VaultRepository._({required this.vaultFilePath, required this.crypto});

  static Future<VaultRepository> create() async {
    final baseDir = await getApplicationSupportDirectory();
    final dir = Directory(p.join(baseDir.path, 'RescueAuthKit'));
    final filePath = p.join(dir.path, vaultFileName);
    return VaultRepository._(vaultFilePath: filePath, crypto: VaultCrypto());
  }

  static VaultRepository forPath({
    required String vaultFilePath,
    VaultCrypto? crypto,
  }) {
    return VaultRepository._(
      vaultFilePath: vaultFilePath,
      crypto: crypto ?? VaultCrypto(),
    );
  }

  Future<bool> vaultFileExists() async {
    return File(vaultFilePath).exists();
  }

  Future<VaultHandle> createNewVault({required String password}) async {
    final salt = crypto.newSalt();
    final kdfParams = VaultKdfParams.defaultParams(salt: salt);
    final key = await crypto.deriveKeyFromPassword(
      password: password,
      params: kdfParams,
    );

    final data = VaultData.empty();
    await _writeEncrypted(data: data, key: key, kdfParams: kdfParams);

    return VaultHandle(
      data: data,
      key: key,
      kdfParams: kdfParams,
      cipher: rescueAuthKitCipherXchacha20Poly1305,
    );
  }

  Future<VaultHandle> open({required String password}) async {
    final file = File(vaultFilePath);
    if (!await file.exists()) {
      throw const VaultIoException('Vault file not found');
    }

    final bytes = await file.readAsBytes();
    final vaultFile = VaultFile.decode(Uint8List.fromList(bytes));

    if (vaultFile.cipher != rescueAuthKitCipherXchacha20Poly1305) {
      throw const VaultFormatException('Unsupported cipher');
    }

    final key = await crypto.deriveKeyFromPassword(
      password: password,
      params: vaultFile.kdf,
    );

    try {
      final clearBytes = await crypto.decryptFile(file: vaultFile, key: key);
      final obj = jsonDecode(utf8.decode(clearBytes)) as Object?;
      if (obj is! Map<String, dynamic>) {
        throw const VaultFormatException(
          'Decrypted payload is not a JSON object',
        );
      }
      final data = _upgradeDataIfNeeded(VaultData.fromJson(obj));
      if (data.schemaVersion != (obj['schemaVersion'] as int? ?? 1)) {
        await _writeEncrypted(data: data, key: key, kdfParams: vaultFile.kdf);
      }

      return VaultHandle(
        data: data,
        key: key,
        kdfParams: vaultFile.kdf,
        cipher: vaultFile.cipher,
      );
    } on SecretBoxAuthenticationError {
      throw const VaultAuthException();
    } on FormatException catch (e) {
      throw VaultFormatException('Invalid vault payload: $e');
    }
  }

  Future<void> save(VaultHandle handle) async {
    await _writeEncrypted(
      data: handle.data,
      key: handle.key,
      kdfParams: handle.kdfParams,
    );
  }

  Future<Uint8List> exportBytes() async {
    final file = File(vaultFilePath);
    if (!await file.exists()) {
      throw const VaultIoException('Vault file not found');
    }
    return Uint8List.fromList(await file.readAsBytes());
  }

  Future<VaultHandle> importBytes({
    required Uint8List bytes,
    required String password,
  }) async {
    final vaultFile = VaultFile.decode(bytes);

    if (vaultFile.cipher != rescueAuthKitCipherXchacha20Poly1305) {
      throw const VaultFormatException('Unsupported cipher');
    }

    final key = await crypto.deriveKeyFromPassword(
      password: password,
      params: vaultFile.kdf,
    );

    try {
      final clearBytes = await crypto.decryptFile(file: vaultFile, key: key);
      final obj = jsonDecode(utf8.decode(clearBytes)) as Object?;
      if (obj is! Map<String, dynamic>) {
        throw const VaultFormatException(
          'Decrypted payload is not a JSON object',
        );
      }
      final data = _upgradeDataIfNeeded(VaultData.fromJson(obj));

      await _writeEncrypted(data: data, key: key, kdfParams: vaultFile.kdf);

      return VaultHandle(
        data: data,
        key: key,
        kdfParams: vaultFile.kdf,
        cipher: vaultFile.cipher,
      );
    } on SecretBoxAuthenticationError {
      throw const VaultAuthException();
    }
  }

  Future<void> _writeEncrypted({
    required VaultData data,
    required SecretKey key,
    required VaultKdfParams kdfParams,
  }) async {
    final clearJson = jsonEncode(data.toJson());
    final clearBytes = Uint8List.fromList(utf8.encode(clearJson));

    final vaultFile = await crypto.encryptToFile(
      cleartextJsonBytes: clearBytes,
      key: key,
      kdfParams: kdfParams,
    );

    await _atomicWrite(vaultFile.encode());
  }

  /// "Good enough" atomic-ish write:
  /// write tmp -> rename old to .bak -> rename tmp -> delete .bak
  Future<void> _atomicWrite(Uint8List bytes) async {
    final file = File(vaultFilePath);
    await file.parent.create(recursive: true);

    final tmp = File('${file.path}.tmp');
    final bak = File('${file.path}.bak');

    await tmp.writeAsBytes(bytes, flush: true);

    if (await bak.exists()) {
      await bak.delete();
    }

    if (await file.exists()) {
      try {
        await file.rename(bak.path);
      } catch (_) {
        await bak.writeAsBytes(await file.readAsBytes(), flush: true);
        await file.delete();
      }
    }

    await tmp.rename(file.path);

    if (await bak.exists()) {
      await bak.delete();
    }
  }

  VaultData _upgradeDataIfNeeded(VaultData data) {
    if (data.schemaVersion >= vaultDataSchemaVersion) {
      return data;
    }
    return data.copyWith();
  }
}
