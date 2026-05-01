// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'RescueAuthKit';

  @override
  String get vaultLockedTitle => 'Vault Locked';

  @override
  String get unlockVaultTitle => 'Unlock Vault';

  @override
  String get createVaultTitle => 'Create Vault';

  @override
  String get createWarning =>
      'Master password cannot be recovered. Save it in a password manager.';

  @override
  String get masterPasswordLabel => 'Master Password';

  @override
  String get confirmMasterPasswordLabel => 'Confirm Master Password';

  @override
  String get unlockButton => 'Unlock';

  @override
  String get createAndUnlockButton => 'Create and Unlock';

  @override
  String get passwordMinLengthError =>
      'Master password must be at least 10 characters.';

  @override
  String get passwordMismatchError => 'Passwords do not match.';

  @override
  String unlockFailed(Object error) {
    return 'Failed to unlock vault: $error';
  }

  @override
  String createFailed(Object error) {
    return 'Failed to create vault: $error';
  }

  @override
  String get incorrectPassword => 'Incorrect password (or vault is corrupted).';

  @override
  String get lockTooltip => 'Lock Vault';

  @override
  String get tabTotp => 'TOTP';

  @override
  String get tabRecovery => 'Recovery';

  @override
  String get tabBackup => 'Backup';

  @override
  String get tabDeveloper => 'Developer';

  @override
  String get tabSettings => 'Settings';

  @override
  String get settingsVaultSection => 'Vault Backup';

  @override
  String get settingsFeaturesSection => 'Features';

  @override
  String get settingsDeveloperBackupTitle => 'Developer Backup';

  @override
  String get settingsDeveloperBackupSubtitle =>
      'Store Android signing keys, API keys, SSH keys, env vars, and other developer secrets in the encrypted vault.';

  @override
  String get settingsVersionSection => 'Version';

  @override
  String get settingsVersionTitle => 'Version information';

  @override
  String get settingsVersionSubtitle =>
      'Checks GitHub Releases for newer RescueAuthKit builds.';

  @override
  String get settingsLoadingVersion => 'Loading version...';

  @override
  String get settingsUnknownVersion => 'Unknown version';

  @override
  String settingsAppVersion(Object version) {
    return 'Current version: $version';
  }

  @override
  String get settingsCheckUpdates => 'Check for updates';

  @override
  String get settingsCheckingUpdates => 'Checking...';

  @override
  String get settingsOpenRelease => 'Open release';

  @override
  String settingsUpdateAvailable(Object version) {
    return 'New version available: $version';
  }

  @override
  String settingsNoUpdate(Object version) {
    return 'Already on latest version: $version';
  }

  @override
  String get settingsNoReleaseFound => 'No GitHub release was found yet.';

  @override
  String settingsUpdateCompareFailed(Object version) {
    return 'Found GitHub release $version, but its tag cannot be compared.';
  }

  @override
  String settingsUpdateCheckFailed(Object error) {
    return 'Update check failed: $error';
  }

  @override
  String get totpEmpty => 'No TOTP entries yet. Tap + to import.';

  @override
  String get totpCopied => 'TOTP code copied';

  @override
  String totpExpiresIn(Object seconds) {
    return 'Expires in $seconds seconds';
  }

  @override
  String get totpNoIssuer => '(No issuer)';

  @override
  String get totpDeleteTitle => 'Delete this TOTP entry?';

  @override
  String get addTotpSheetScan => 'Scan QR';

  @override
  String get addTotpSheetPaste => 'Paste otpauth URI';

  @override
  String get pasteDialogTitle => 'Paste otpauth URI';

  @override
  String get pasteDialogHint => 'otpauth://totp/Issuer:Account?secret=...';

  @override
  String get dialogCancel => 'Cancel';

  @override
  String get dialogContinue => 'Continue';

  @override
  String get confirmImportTitle => 'Confirm Import';

  @override
  String confirmImportParseError(Object error) {
    return 'Parsing error: $error';
  }

  @override
  String get confirmImportHint =>
      'Hint: only otpauth://totp/... URIs are supported.';

  @override
  String get issuerLabel => 'Issuer';

  @override
  String get accountLabel => 'Account';

  @override
  String get algoDigitsPeriod => 'Algorithm / Digits / Period';

  @override
  String get saveToVault => 'Save to Vault';

  @override
  String get importSaved => 'TOTP entry saved';

  @override
  String importSaveFailed(Object error) {
    return 'Failed to save TOTP entry: $error';
  }

  @override
  String get recoveryEmpty => 'No recovery codes yet. Tap + to add.';

  @override
  String get recoveryNoTitle => '(No title)';

  @override
  String recoveryCodesCount(Object count) {
    return '$count codes';
  }

  @override
  String get recoveryDeleteTitle => 'Delete this recovery set?';

  @override
  String get deleteButton => 'Delete';

  @override
  String get copyAllTooltip => 'Copy all';

  @override
  String get copied => 'Copied';

  @override
  String get addRecoveryTitle => 'Add Recovery Codes';

  @override
  String get titleOptionalLabel => 'Title (optional)';

  @override
  String get recoveryCodesLabel => 'Recovery codes (one per line)';

  @override
  String get recoveryNeedOne => 'Enter at least one code.';

  @override
  String get recoverySaved => 'Recovery codes saved';

  @override
  String recoverySaveFailed(Object error) {
    return 'Save failed: $error';
  }

  @override
  String get backupCurrentPath => 'Current vault path:';

  @override
  String get backupExport => 'Export Vault';

  @override
  String get backupImport => 'Import Vault';

  @override
  String get backupExportShared => 'Backup file generated and shared';

  @override
  String backupExportedTo(Object path) {
    return 'Vault exported to $path';
  }

  @override
  String backupExportFailed(Object error) {
    return 'Error exporting vault: $error';
  }

  @override
  String get backupImportReplaceTitle =>
      'Import will replace the current vault';

  @override
  String get backupImportReplaceBody =>
      'Are you sure? It is recommended to export the current vault first.';

  @override
  String get backupPasswordTitle => 'Enter the backup\'s master password';

  @override
  String backupImportedFrom(Object name) {
    return 'Vault imported from $name';
  }

  @override
  String get backupWrongPassword =>
      'Incorrect password (or backup file is corrupted)';

  @override
  String backupImportFailed(Object error) {
    return 'Error importing vault: $error';
  }

  @override
  String get developerAddTitle => 'Add developer backup';

  @override
  String get developerEmpty =>
      'No developer backups yet. Tap + to add Android signing keys, API keys, SSH keys, environment variables, or generic secrets.';

  @override
  String get developerAndroidSigningKey => 'Android Signing Key';

  @override
  String get developerApiCredential => 'API Credential';

  @override
  String get developerSshKey => 'SSH Key';

  @override
  String get developerEnvVarSet => 'Environment Variables';

  @override
  String get developerGenericSecret => 'Generic Secret';

  @override
  String get developerSave => 'Save';

  @override
  String get developerTitleLabel => 'Title';

  @override
  String get developerNotesLabel => 'Notes';

  @override
  String get developerProjectNameLabel => 'Project name';

  @override
  String get developerPackageNameLabel => 'Package name';

  @override
  String get developerKeystoreFileLabel => 'Keystore file';

  @override
  String get developerChooseFile => 'Choose .jks / .keystore file';

  @override
  String get developerServiceNameLabel => 'Service name';

  @override
  String get developerApiKeyLabel => 'API key';

  @override
  String get developerApiSecretLabel => 'API secret';

  @override
  String get developerKeyNameLabel => 'Key name';

  @override
  String get developerPublicKeyLabel => 'Public key';

  @override
  String get developerPrivateKeyLabel => 'Private key';

  @override
  String get developerPassphraseLabel => 'Passphrase';

  @override
  String get developerEnvVariablesLabel =>
      'Environment variables, one NAME=value per line';

  @override
  String get developerGenericFieldsLabel => 'Fields, one label=value per line';

  @override
  String get developerFileRequired => 'Choose a keystore file first.';

  @override
  String get developerSaved => 'Developer backup saved';

  @override
  String developerSaveFailed(Object error) {
    return 'Save failed: $error';
  }

  @override
  String get developerEntryMissing => 'This developer backup no longer exists.';

  @override
  String get developerEdit => 'Edit';

  @override
  String get developerDeleteTitle => 'Delete this developer backup?';

  @override
  String get developerExportKeystore => 'Export keystore file';

  @override
  String get developerCopyKeyProperties => 'Copy key.properties';

  @override
  String get developerFileShared => 'Keystore file generated and shared';

  @override
  String developerFileExported(Object path) {
    return 'Keystore exported to $path';
  }

  @override
  String get developerShowSecret => 'Show secret';

  @override
  String get developerHideSecret => 'Hide secret';
}
