// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Chinese (`zh`).
class AppLocalizationsZh extends AppLocalizations {
  AppLocalizationsZh([String locale = 'zh']) : super(locale);

  @override
  String get appTitle => 'RescueAuthKit';

  @override
  String get vaultLockedTitle => 'Vault 已锁定';

  @override
  String get unlockVaultTitle => '解锁 Vault';

  @override
  String get createVaultTitle => '创建 Vault';

  @override
  String get createWarning => '主密码无法找回，请用密码管理器保存。';

  @override
  String get masterPasswordLabel => '主密码';

  @override
  String get confirmMasterPasswordLabel => '确认主密码';

  @override
  String get unlockButton => '解锁';

  @override
  String get createAndUnlockButton => '创建并解锁';

  @override
  String get passwordMinLengthError => '主密码至少需要 10 个字符。';

  @override
  String get passwordMismatchError => '两次输入不一致。';

  @override
  String unlockFailed(Object error) {
    return '解锁失败：$error';
  }

  @override
  String createFailed(Object error) {
    return '创建失败：$error';
  }

  @override
  String get incorrectPassword => '密码错误（或 Vault 已损坏）。';

  @override
  String get lockTooltip => '锁定 Vault';

  @override
  String get tabTotp => 'TOTP';

  @override
  String get tabRecovery => '恢复码';

  @override
  String get tabBackup => '备份';

  @override
  String get totpEmpty => '还没有 TOTP，点击 + 导入。';

  @override
  String get totpCopied => '已复制验证码';

  @override
  String totpExpiresIn(Object seconds) {
    return '剩余 $seconds 秒';
  }

  @override
  String get totpNoIssuer => '（无发行方）';

  @override
  String get addTotpSheetScan => '扫码导入';

  @override
  String get addTotpSheetPaste => '粘贴 otpauth URI';

  @override
  String get pasteDialogTitle => '粘贴 otpauth URI';

  @override
  String get pasteDialogHint => 'otpauth://totp/Issuer:Account?secret=...';

  @override
  String get dialogCancel => '取消';

  @override
  String get dialogContinue => '继续';

  @override
  String get confirmImportTitle => '确认导入';

  @override
  String confirmImportParseError(Object error) {
    return '解析失败：$error';
  }

  @override
  String get confirmImportHint => '提示：目前仅支持 otpauth://totp/... URI。';

  @override
  String get issuerLabel => 'Issuer';

  @override
  String get accountLabel => 'Account';

  @override
  String get algoDigitsPeriod => '算法 / 位数 / 周期';

  @override
  String get saveToVault => '保存到 Vault';

  @override
  String get importSaved => '已保存 TOTP';

  @override
  String importSaveFailed(Object error) {
    return '保存失败：$error';
  }

  @override
  String get recoveryEmpty => '还没有恢复码，点击 + 添加。';

  @override
  String get recoveryNoTitle => '（无标题）';

  @override
  String recoveryCodesCount(Object count) {
    return '$count 个恢复码';
  }

  @override
  String get recoveryDeleteTitle => '删除这组恢复码？';

  @override
  String get deleteButton => '删除';

  @override
  String get copyAllTooltip => '复制全部';

  @override
  String get copied => '已复制';

  @override
  String get addRecoveryTitle => '新增恢复码';

  @override
  String get titleOptionalLabel => '标题（可选）';

  @override
  String get recoveryCodesLabel => '恢复码（每行一个）';

  @override
  String get recoveryNeedOne => '至少输入一个恢复码。';

  @override
  String get recoverySaved => '恢复码已保存';

  @override
  String recoverySaveFailed(Object error) {
    return '保存失败：$error';
  }

  @override
  String get backupCurrentPath => '当前 Vault 路径：';

  @override
  String get backupExport => '导出备份';

  @override
  String get backupImport => '导入备份';

  @override
  String get backupExportShared => '备份文件已生成并分享';

  @override
  String backupExportedTo(Object path) {
    return '已导出到：$path';
  }

  @override
  String backupExportFailed(Object error) {
    return '导出失败：$error';
  }

  @override
  String get backupImportReplaceTitle => '导入会覆盖当前 Vault';

  @override
  String get backupImportReplaceBody => '确认继续？建议先导出当前备份。';

  @override
  String get backupPasswordTitle => '请输入备份文件的主密码';

  @override
  String backupImportedFrom(Object name) {
    return '已从 $name 导入';
  }

  @override
  String get backupWrongPassword => '密码错误（或备份文件损坏）';

  @override
  String backupImportFailed(Object error) {
    return '导入失败：$error';
  }
}
