import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/vault/vault_models.dart';
import '../../core/vault/vault_session.dart';
import '../../l10n/app_localizations.dart';

/// Shows a dialog letting the user move [account] to a different provider —
/// either an existing one (dropdown) or a brand-new one (text field).
///
/// Returns the resolved new provider id on success, or `null` if the user
/// cancelled. Persistence and `notifyListeners` happen inside the dialog.
Future<String?> showMoveAccountDialog(
  BuildContext context, {
  required Account account,
}) async {
  return showDialog<String?>(
    context: context,
    builder: (ctx) => _MoveAccountDialog(account: account),
  );
}

class _MoveAccountDialog extends StatefulWidget {
  const _MoveAccountDialog({required this.account});

  final Account account;

  @override
  State<_MoveAccountDialog> createState() => _MoveAccountDialogState();
}

enum _Mode { existing, newProvider }

class _MoveAccountDialogState extends State<_MoveAccountDialog> {
  late _Mode _mode;
  String? _selectedProviderId;
  final TextEditingController _newProviderCtrl = TextEditingController();
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _newProviderCtrl.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _newProviderCtrl.dispose();
    super.dispose();
  }

  bool get _canConfirm {
    if (_saving) return false;
    switch (_mode) {
      case _Mode.existing:
        return _selectedProviderId != null &&
            _selectedProviderId != widget.account.providerId;
      case _Mode.newProvider:
        return _newProviderCtrl.text.trim().isNotEmpty;
    }
  }

  Future<void> _confirm() async {
    final session = context.read<VaultSession>();
    setState(() => _saving = true);
    try {
      String newProviderId;
      switch (_mode) {
        case _Mode.existing:
          newProviderId = _selectedProviderId!;
        case _Mode.newProvider:
          final created = await session.addProvider(
            name: _newProviderCtrl.text.trim(),
          );
          newProviderId = created.id;
      }
      await session.moveAccountToProvider(
        accountId: widget.account.id,
        newProviderId: newProviderId,
      );
      if (!mounted) return;
      Navigator.of(context).pop(newProviderId);
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

    final otherProviders = data.providers
        .where((p) => p.id != widget.account.providerId)
        .toList(growable: false);

    // Decide the initial mode lazily on first build:
    // - If there are other providers, default to "Existing".
    // - Otherwise, only the "New" option makes sense.
    if (!_modeInitialized) {
      _mode = otherProviders.isNotEmpty ? _Mode.existing : _Mode.newProvider;
      _modeInitialized = true;
    }

    return AlertDialog(
      title: Text(l10n.accountMoveTitle),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (otherProviders.isNotEmpty)
            SegmentedButton<_Mode>(
              segments: [
                ButtonSegment(
                  value: _Mode.existing,
                  label: Text(l10n.pickerModeExistingProvider),
                ),
                ButtonSegment(
                  value: _Mode.newProvider,
                  label: Text(l10n.pickerModeNewProvider),
                ),
              ],
              selected: {_mode},
              onSelectionChanged: (s) => setState(() => _mode = s.first),
            ),
          const SizedBox(height: 12),
          if (_mode == _Mode.existing && otherProviders.isNotEmpty)
            DropdownButtonFormField<String>(
              initialValue: _selectedProviderId,
              decoration: InputDecoration(
                labelText: l10n.providerNameLabel,
                border: const OutlineInputBorder(),
                isDense: true,
              ),
              items: [
                for (final p in otherProviders)
                  DropdownMenuItem(value: p.id, child: Text(p.name)),
              ],
              onChanged: (v) => setState(() => _selectedProviderId = v),
            ),
          if (_mode == _Mode.newProvider)
            TextField(
              controller: _newProviderCtrl,
              autofocus: true,
              decoration: InputDecoration(
                labelText: l10n.providerNameLabel,
                border: const OutlineInputBorder(),
                isDense: true,
              ),
            ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: _saving ? null : () => Navigator.of(context).pop(null),
          child: Text(l10n.dialogCancel),
        ),
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

  bool _modeInitialized = false;
}
