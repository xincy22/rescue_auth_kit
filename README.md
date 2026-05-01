# RescueAuthKit

[English](README.md) | [中文](README.zh-CN.md)

RescueAuthKit is a small, opinionated 2FA vault focused on one thing: reliable
import/export so you can move your TOTP secrets and recovery codes between
devices without guessing which app supports what.

## Why I built this

Most authenticator apps make migration the hardest part of the experience. This
project flips the priority:

- Your data lives in one encrypted vault file.
- Backup and restore are first-class features, not an afterthought.
- The goal is "phone <-> desktop" recovery that you can actually trust.

## What is special here

- Single encrypted vault file you can copy anywhere.
- Strong password-based encryption:
  - Argon2id for key derivation
  - XChaCha20-Poly1305 for authenticated encryption
- Cross-platform migration flow:
  - Export on one device, import on another, verify the same codes.

## MVP Features

- TOTP codes with live countdown and copy
- Recovery codes: add, view, copy, delete
- TOTP import:
  - Android: QR scan
  - Desktop: paste `otpauth://totp/...`
- Encrypted backup import/export (the core feature)

## Supported Platforms (current focus)

- Windows desktop
- Android

Web is not supported (the vault uses local file IO).

## Run locally

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

## Backup / Restore (the intended flow)

1. Create and unlock the vault on Device A
2. Import a few TOTP entries and/or recovery codes
3. Export from the Settings tab
4. Import that vault file on Device B using the same master password
5. Confirm the same TOTP codes appear on both devices

## Notes and limitations

- `otpauth-migration://` is not supported in this MVP.
- Forgetting the master password means the vault cannot be decrypted.
