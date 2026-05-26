import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../../l10n/app_localizations.dart';
import '../scan/confirm_import_screen.dart';
import '../scan/paste_uri_dialog.dart';
import '../scan/scan_screen.dart';
import 'add_recovery_codes_screen.dart';

/// The unified add-credential bottom sheet, presented from the providers/
/// accounts FAB or the [AccountDetailScreen]'s "Add credential" action.
///
/// Offers three options:
/// - Scan QR (Android only)
/// - Paste otpauth URI
/// - Add recovery codes
///
/// Pre-bind hints:
/// - When [targetAccountId] is provided, the credential is attached directly
///   to that account without showing the picker sheet.
/// - When [targetProviderId] is provided (and no targetAccountId), the
///   subsequent picker is locked to that provider.
class AddCredentialSheet extends StatelessWidget {
  const AddCredentialSheet({
    super.key,
    this.targetAccountId,
    this.targetProviderId,
  });

  final String? targetAccountId;
  final String? targetProviderId;

  static Future<void> show(
    BuildContext context, {
    String? targetAccountId,
    String? targetProviderId,
  }) async {
    await showModalBottomSheet<void>(
      context: context,
      builder: (ctx) => AddCredentialSheet(
        targetAccountId: targetAccountId,
        targetProviderId: targetProviderId,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final isAndroid =
        !kIsWeb && defaultTargetPlatform == TargetPlatform.android;

    return SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Text(
              l10n.addCredentialSheetTitle,
              style: Theme.of(context).textTheme.titleLarge,
            ),
          ),
          if (isAndroid)
            ListTile(
              leading: const Icon(Icons.qr_code_scanner),
              title: Text(l10n.addCredentialScan),
              onTap: () => _handleScan(context),
            ),
          ListTile(
            leading: const Icon(Icons.paste),
            title: Text(l10n.addCredentialPaste),
            onTap: () => _handlePaste(context),
          ),
          ListTile(
            leading: const Icon(Icons.key),
            title: Text(l10n.addCredentialRecoveryCodes),
            onTap: () => _handleRecoveryCodes(context),
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }

  Future<void> _handleScan(BuildContext context) async {
    Navigator.of(context).pop(); // dismiss the sheet

    final uriText = await Navigator.of(context).push<String?>(
      MaterialPageRoute(builder: (_) => const ScanScreen()),
    );

    if (!context.mounted || uriText == null || uriText.trim().isEmpty) return;

    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => ConfirmImportScreen(
          otpauthUri: uriText,
          targetAccountId: targetAccountId,
          targetProviderId: targetProviderId,
        ),
      ),
    );
  }

  Future<void> _handlePaste(BuildContext context) async {
    Navigator.of(context).pop();

    final uriText = await showPasteOtpauthDialog(context);

    if (!context.mounted || uriText == null || uriText.trim().isEmpty) return;

    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => ConfirmImportScreen(
          otpauthUri: uriText,
          targetAccountId: targetAccountId,
          targetProviderId: targetProviderId,
        ),
      ),
    );
  }

  Future<void> _handleRecoveryCodes(BuildContext context) async {
    Navigator.of(context).pop();
    if (!context.mounted) return;

    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => AddRecoveryCodesScreen(
          targetAccountId: targetAccountId,
          targetProviderId: targetProviderId,
        ),
      ),
    );
  }
}
