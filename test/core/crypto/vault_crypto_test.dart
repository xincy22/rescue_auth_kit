import 'dart:convert';
import 'dart:typed_data';

import 'package:cryptography/cryptography.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rescue_auth_kit/core/crypto/vault_crypto.dart';

void main() {
  test('encrypt -> decode -> decrypt returns original bytes', () async {
    final crypto = VaultCrypto();
    final salt = crypto.newSalt();
    final kdf = VaultKdfParams.forTesting(salt: salt);

    final password = 'correct horse battery staple';
    final key = await crypto.deriveKeyFromPassword(
      password: password,
      params: kdf,
    );

    final payloadBytes = Uint8List.fromList(utf8.encode('{"hello":"world"}'));

    final file = await crypto.encryptToFile(
      cleartextJsonBytes: payloadBytes,
      key: key,
      kdfParams: kdf,
    );

    final decoded = VaultFile.decode(file.encode());

    final clear = await crypto.decryptFile(file: decoded, key: key);

    expect(clear, payloadBytes);
  });

  test('wrong password fails to decrypt', () async {
    final crypto = VaultCrypto();
    final salt = crypto.newSalt();
    final kdf = VaultKdfParams.forTesting(salt: salt);

    final rightKey = await crypto.deriveKeyFromPassword(
      password: "right",
      params: kdf,
    );
    final wrongKey = await crypto.deriveKeyFromPassword(
      password: "wrong",
      params: kdf,
    );

    final payloadBytes = Uint8List.fromList(utf8.encode('{"hello":"world"}'));

    final file = await crypto.encryptToFile(
      cleartextJsonBytes: payloadBytes,
      key: rightKey,
      kdfParams: kdf,
    );

    expect(
      () async => crypto.decryptFile(file: file, key: wrongKey),
      throwsA(isA<SecretBoxAuthenticationError>()),
    );
  });
}
