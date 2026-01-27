import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_zh.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('zh'),
  ];

  /// No description provided for @appTitle.
  ///
  /// In en, this message translates to:
  /// **'RescueAuthKit'**
  String get appTitle;

  /// No description provided for @vaultLockedTitle.
  ///
  /// In en, this message translates to:
  /// **'Vault Locked'**
  String get vaultLockedTitle;

  /// No description provided for @unlockVaultTitle.
  ///
  /// In en, this message translates to:
  /// **'Unlock Vault'**
  String get unlockVaultTitle;

  /// No description provided for @createVaultTitle.
  ///
  /// In en, this message translates to:
  /// **'Create Vault'**
  String get createVaultTitle;

  /// No description provided for @createWarning.
  ///
  /// In en, this message translates to:
  /// **'Master password cannot be recovered. Save it in a password manager.'**
  String get createWarning;

  /// No description provided for @masterPasswordLabel.
  ///
  /// In en, this message translates to:
  /// **'Master Password'**
  String get masterPasswordLabel;

  /// No description provided for @confirmMasterPasswordLabel.
  ///
  /// In en, this message translates to:
  /// **'Confirm Master Password'**
  String get confirmMasterPasswordLabel;

  /// No description provided for @unlockButton.
  ///
  /// In en, this message translates to:
  /// **'Unlock'**
  String get unlockButton;

  /// No description provided for @createAndUnlockButton.
  ///
  /// In en, this message translates to:
  /// **'Create and Unlock'**
  String get createAndUnlockButton;

  /// No description provided for @passwordMinLengthError.
  ///
  /// In en, this message translates to:
  /// **'Master password must be at least 10 characters.'**
  String get passwordMinLengthError;

  /// No description provided for @passwordMismatchError.
  ///
  /// In en, this message translates to:
  /// **'Passwords do not match.'**
  String get passwordMismatchError;

  /// No description provided for @unlockFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed to unlock vault: {error}'**
  String unlockFailed(Object error);

  /// No description provided for @createFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed to create vault: {error}'**
  String createFailed(Object error);

  /// No description provided for @incorrectPassword.
  ///
  /// In en, this message translates to:
  /// **'Incorrect password (or vault is corrupted).'**
  String get incorrectPassword;

  /// No description provided for @lockTooltip.
  ///
  /// In en, this message translates to:
  /// **'Lock Vault'**
  String get lockTooltip;

  /// No description provided for @tabTotp.
  ///
  /// In en, this message translates to:
  /// **'TOTP'**
  String get tabTotp;

  /// No description provided for @tabRecovery.
  ///
  /// In en, this message translates to:
  /// **'Recovery'**
  String get tabRecovery;

  /// No description provided for @tabBackup.
  ///
  /// In en, this message translates to:
  /// **'Backup'**
  String get tabBackup;

  /// No description provided for @totpEmpty.
  ///
  /// In en, this message translates to:
  /// **'No TOTP entries yet. Tap + to import.'**
  String get totpEmpty;

  /// No description provided for @totpCopied.
  ///
  /// In en, this message translates to:
  /// **'TOTP code copied'**
  String get totpCopied;

  /// No description provided for @totpExpiresIn.
  ///
  /// In en, this message translates to:
  /// **'Expires in {seconds} seconds'**
  String totpExpiresIn(Object seconds);

  /// No description provided for @totpNoIssuer.
  ///
  /// In en, this message translates to:
  /// **'(No issuer)'**
  String get totpNoIssuer;

  /// No description provided for @addTotpSheetScan.
  ///
  /// In en, this message translates to:
  /// **'Scan QR'**
  String get addTotpSheetScan;

  /// No description provided for @addTotpSheetPaste.
  ///
  /// In en, this message translates to:
  /// **'Paste otpauth URI'**
  String get addTotpSheetPaste;

  /// No description provided for @pasteDialogTitle.
  ///
  /// In en, this message translates to:
  /// **'Paste otpauth URI'**
  String get pasteDialogTitle;

  /// No description provided for @pasteDialogHint.
  ///
  /// In en, this message translates to:
  /// **'otpauth://totp/Issuer:Account?secret=...'**
  String get pasteDialogHint;

  /// No description provided for @dialogCancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get dialogCancel;

  /// No description provided for @dialogContinue.
  ///
  /// In en, this message translates to:
  /// **'Continue'**
  String get dialogContinue;

  /// No description provided for @confirmImportTitle.
  ///
  /// In en, this message translates to:
  /// **'Confirm Import'**
  String get confirmImportTitle;

  /// No description provided for @confirmImportParseError.
  ///
  /// In en, this message translates to:
  /// **'Parsing error: {error}'**
  String confirmImportParseError(Object error);

  /// No description provided for @confirmImportHint.
  ///
  /// In en, this message translates to:
  /// **'Hint: only otpauth://totp/... URIs are supported.'**
  String get confirmImportHint;

  /// No description provided for @issuerLabel.
  ///
  /// In en, this message translates to:
  /// **'Issuer'**
  String get issuerLabel;

  /// No description provided for @accountLabel.
  ///
  /// In en, this message translates to:
  /// **'Account'**
  String get accountLabel;

  /// No description provided for @algoDigitsPeriod.
  ///
  /// In en, this message translates to:
  /// **'Algorithm / Digits / Period'**
  String get algoDigitsPeriod;

  /// No description provided for @saveToVault.
  ///
  /// In en, this message translates to:
  /// **'Save to Vault'**
  String get saveToVault;

  /// No description provided for @importSaved.
  ///
  /// In en, this message translates to:
  /// **'TOTP entry saved'**
  String get importSaved;

  /// No description provided for @importSaveFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed to save TOTP entry: {error}'**
  String importSaveFailed(Object error);

  /// No description provided for @recoveryEmpty.
  ///
  /// In en, this message translates to:
  /// **'No recovery codes yet. Tap + to add.'**
  String get recoveryEmpty;

  /// No description provided for @recoveryNoTitle.
  ///
  /// In en, this message translates to:
  /// **'(No title)'**
  String get recoveryNoTitle;

  /// No description provided for @recoveryCodesCount.
  ///
  /// In en, this message translates to:
  /// **'{count} codes'**
  String recoveryCodesCount(Object count);

  /// No description provided for @recoveryDeleteTitle.
  ///
  /// In en, this message translates to:
  /// **'Delete this recovery set?'**
  String get recoveryDeleteTitle;

  /// No description provided for @deleteButton.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get deleteButton;

  /// No description provided for @copyAllTooltip.
  ///
  /// In en, this message translates to:
  /// **'Copy all'**
  String get copyAllTooltip;

  /// No description provided for @copied.
  ///
  /// In en, this message translates to:
  /// **'Copied'**
  String get copied;

  /// No description provided for @addRecoveryTitle.
  ///
  /// In en, this message translates to:
  /// **'Add Recovery Codes'**
  String get addRecoveryTitle;

  /// No description provided for @titleOptionalLabel.
  ///
  /// In en, this message translates to:
  /// **'Title (optional)'**
  String get titleOptionalLabel;

  /// No description provided for @recoveryCodesLabel.
  ///
  /// In en, this message translates to:
  /// **'Recovery codes (one per line)'**
  String get recoveryCodesLabel;

  /// No description provided for @recoveryNeedOne.
  ///
  /// In en, this message translates to:
  /// **'Enter at least one code.'**
  String get recoveryNeedOne;

  /// No description provided for @recoverySaved.
  ///
  /// In en, this message translates to:
  /// **'Recovery codes saved'**
  String get recoverySaved;

  /// No description provided for @recoverySaveFailed.
  ///
  /// In en, this message translates to:
  /// **'Save failed: {error}'**
  String recoverySaveFailed(Object error);

  /// No description provided for @backupCurrentPath.
  ///
  /// In en, this message translates to:
  /// **'Current vault path:'**
  String get backupCurrentPath;

  /// No description provided for @backupExport.
  ///
  /// In en, this message translates to:
  /// **'Export Vault'**
  String get backupExport;

  /// No description provided for @backupImport.
  ///
  /// In en, this message translates to:
  /// **'Import Vault'**
  String get backupImport;

  /// No description provided for @backupExportShared.
  ///
  /// In en, this message translates to:
  /// **'Backup file generated and shared'**
  String get backupExportShared;

  /// No description provided for @backupExportedTo.
  ///
  /// In en, this message translates to:
  /// **'Vault exported to {path}'**
  String backupExportedTo(Object path);

  /// No description provided for @backupExportFailed.
  ///
  /// In en, this message translates to:
  /// **'Error exporting vault: {error}'**
  String backupExportFailed(Object error);

  /// No description provided for @backupImportReplaceTitle.
  ///
  /// In en, this message translates to:
  /// **'Import will replace the current vault'**
  String get backupImportReplaceTitle;

  /// No description provided for @backupImportReplaceBody.
  ///
  /// In en, this message translates to:
  /// **'Are you sure? It is recommended to export the current vault first.'**
  String get backupImportReplaceBody;

  /// No description provided for @backupPasswordTitle.
  ///
  /// In en, this message translates to:
  /// **'Enter the backup\'s master password'**
  String get backupPasswordTitle;

  /// No description provided for @backupImportedFrom.
  ///
  /// In en, this message translates to:
  /// **'Vault imported from {name}'**
  String backupImportedFrom(Object name);

  /// No description provided for @backupWrongPassword.
  ///
  /// In en, this message translates to:
  /// **'Incorrect password (or backup file is corrupted)'**
  String get backupWrongPassword;

  /// No description provided for @backupImportFailed.
  ///
  /// In en, this message translates to:
  /// **'Error importing vault: {error}'**
  String backupImportFailed(Object error);

  /// No description provided for @backupChecklist.
  ///
  /// In en, this message translates to:
  /// **'Suggested verification:\n1) Export on phone -> import on desktop\n2) Reset phone -> export on desktop -> import on phone'**
  String get backupChecklist;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en', 'zh'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'zh':
      return AppLocalizationsZh();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
