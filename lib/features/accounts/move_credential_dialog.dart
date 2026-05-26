import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/vault/vault_models.dart';
import '../../core/vault/vault_session.dart';
import '../../l10n/app_localizations.dart';

/// Shows a dialog letting the user move a credential currently inside
/// [fromAccountId] to a different existing account. Persistence happens
/// inside the dialog.
///
/// Returns the chosen destination account id, or `null` if cancelled.
Future<String?> showMoveCredentialDialog(
  BuildContext context, {
  required String fromAccountId,
  required String credentialId,
}) async {
  return showDialog<String?>(
    context: context,
    builder: (ctx) => _MoveCredentialDialog(
      fromAccountId: fromAccountId,
      credentialId: credentialId,
    ),
  );
}

class _MoveCredentialDialog extends StatefulWidget {
  const _MoveCredentialDialog({
    required this.fromAccountId,
    required this.credentialId,
  });

  final String fromAccountId;
  final String credentialId;

  @override
  State<_MoveCredentialDialog> createState() => _MoveCredentialDialogState();
}

class _MoveCredentialDialogState extends State<_MoveCredentialDialog> {
  String? _selectedAccountId;
  bool _saving = false;

  bool get _canConfirm =>
      !_saving &&
      _selectedAccountId != null &&
      _selectedAccountId != widget.fromAccountId;

  Future<void> _confirm() async {
    final session = context.read<VaultSession>();
    setState(() => _saving = true);
    try {
      await session.moveCredentialToAccount(
        fromAccountId: widget.fromAccountId,
        credentialId: widget.credentialId,
        toAccountId: _selectedAccountId!,
      );
      if (!mounted) return;
      Navigator.of(context).pop(_selectedAccountId);
    } catch (_) {
      if (mounted) setState(() => _saving = false);
      rethrow;
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final session = context.watch<VaultSession>();
    final data = session.data;

    final candidates = data.accounts
        .where((a) => a.id != widget.fromAccountId)
        .toList(growable: false);

    return AlertDialog(
      title: Text(l10n.credentialMoveTitle),
      content: candidates.isEmpty
          ? Text(l10n.credentialMoveNoOtherAccounts)
          : SizedBox(
              width: double.maxFinite,
              child: DropdownButtonFormField<String>(
                initialValue: _selectedAccountId,
                isExpanded: true,
                decoration: InputDecoration(
                  labelText: l10n.pickerModeExistingAccount,
                  border: const OutlineInputBorder(),
                  isDense: true,
                ),
                items: [
                  for (final a in candidates)
                    DropdownMenuItem(
                      value: a.id,
                      child: _AccountLabel(account: a, data: data),
                    ),
                ],
                onChanged: (v) => setState(() => _selectedAccountId = v),
              ),
            ),
      actions: [
        TextButton(
          onPressed: _saving ? null : () => Navigator.of(context).pop(null),
          child: Text(l10n.dialogCancel),
        ),
        if (candidates.isNotEmpty)
          FilledButton(
            onPressed: _canConfirm ? _confirm : null,
            child: _saving
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : Text(l10n.accountMoveConfirm),
          ),
      ],
    );
  }
}

class _AccountLabel extends StatelessWidget {
  const _AccountLabel({required this.account, required this.data});

  final Account account;
  final VaultData data;

  @override
  Widget build(BuildContext context) {
    String providerName = '';
    try {
      providerName = data.requireProvider(account.providerId).name;
    } catch (_) {}
    return Text(
      providerName.isNotEmpty
          ? '$providerName  ·  ${account.displayName}'
          : account.displayName,
      overflow: TextOverflow.ellipsis,
    );
  }
}
