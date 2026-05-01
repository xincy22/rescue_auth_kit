# RescueAuthKit

[English](README.md) | [中文](README.zh-CN.md)

RescueAuthKit 是一个很小但很“偏执”的 2FA 密钥库应用，核心目标只有一个：
把导入/导出（迁移与恢复）这件事做得可靠、可验证。

## 我为什么写这个

很多认证器应用在“迁移数据”这件事上体验很差：要么不支持导出，要么格式不通用，
要么流程不清晰。这个项目的优先级正好相反：

- 数据集中存放在一个加密 Vault 文件里
- 备份与恢复是第一优先级能力
- 目标是做到“手机 <-> 桌面端”可验证的闭环迁移

## 这个项目的特别之处

- 单一加密 Vault 文件，可以自由复制与保存
- 强密码学方案（基于主密码）：
  - Argon2id 作为 KDF
  - XChaCha20-Poly1305 作为 AEAD
- 强调跨设备迁移闭环：
  - 一端导出，另一端导入，再验证同样的验证码

## MVP 功能

- TOTP 动态码（实时刷新、倒计时、复制）
- Recovery Codes（新增、查看、复制、删除）
- TOTP 导入：
  - Android：扫码导入
  - 桌面端：粘贴 `otpauth://totp/...`
- 加密备份导出/导入（核心能力）

## 当前重点支持平台

- Windows 桌面端
- Android

暂不支持 Web（Vault 使用本地文件 IO）。

## 本地运行

```bash
flutter pub get
flutter analyze
flutter test
flutter run -d windows
```

Android 运行方式：

```bash
flutter devices
flutter run -d <device-id>
```

## 备份 / 恢复（推荐验证流程）

1. 在设备 A 创建并解锁 Vault
2. 导入一些 TOTP / Recovery Codes
3. 在设置页导出
4. 在设备 B 用同一主密码导入该 Vault 文件
5. 验证两端生成的 TOTP 一致

## 注意与限制

- MVP 不支持 `otpauth-migration://`
- 忘记主密码就无法解密 Vault
