# RescueAuthKit

RescueAuthKit is a Flutter app for securely storing TOTP secrets and recovery
codes in a single encrypted vault file, with cross-device backup/import.

## MVP Features

- Encrypted vault file (Argon2id KDF + XChaCha20-Poly1305 AEAD)
- TOTP list with live codes, countdown, and copy
- TOTP import via:
  - Android QR scan
  - Desktop paste of `otpauth://totp/...` URI
- Recovery codes: add, view, copy, delete
- Backup: encrypted export/import vault file

## Supported Platforms (Current Focus)

- Windows desktop
- Android

Web is not supported (vault uses local file IO).

## Run Locally

```bash
flutter pub get
flutter analyze
flutter test
flutter run -d windows
```

To run on Android:

```bash
flutter devices
flutter run -d <device-id>
```

## Backup / Restore Flow (Recommended)

1. Create/unlock vault on Device A
2. Export backup from the Backup tab
3. Import backup on Device B using the same master password
4. Verify the same TOTP codes appear on both devices

## Notes

- `otpauth-migration://` is not supported in the MVP.
- If you forget the master password, the vault cannot be decrypted.
