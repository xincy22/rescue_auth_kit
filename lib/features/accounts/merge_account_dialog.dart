import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/vault/vault_models.dart';
import '../../core/vault/vault_session.dart';
import '../../l10n/app_localizations.dart';

/// Shows a dialog letting the user merge [source] into another existing
/// account. All credentials of [source] are appended to the target's
/// credentials list (in stored order); [source] is then deleted.
///
/// The target keeps its provider, id, displayName, and createdAt. Only
/// `updatedAt` is bumped.
///
/// Returns the chosen target account id on success, or `null` if cancelled.
Future<String?> showMergeAccountDialog(
  BuildContext context, {
  required Account source,
}) async {
  return showDialog<String?>(
    context: context,
    builder: (ctx) => _MergeAccountDialog(source: source),
  );
}

class _MergeAccountDialog extends StatefulWidget {
  const _MergeAccountDialog({required this.source});
  final Account source;

  @override
  State<_MergeAccountDialog> createState() => _MergeAccountDialogState();
}

class _MergeAccountDialogState extends State<_MergeAccountDialog> {
  String? _selectedTargetId;
  bool _saving = false;

  bool get _canConfirm =>
      !_saving &&
      _selectedTargetId != null &&
      _selectedTargetId != widget.source.id;

  Future<void> _confirm() async {
    final session = context.read<VaultSession>();
    setState(() => _saving = true);
    try {
      await session.mergeAccountInto(
        sourceAccountId: widget.source.id,
        targetAccountId: _selectedTargetId!,
      );
      if (!mounted) return;
      Navigator.of(context).pop(_selectedTargetId);
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
        .where((a) => a.id != widget.source.id)
        .toList(growable: false);

    if (candidates.isEmpty) {
      return AlertDialog(
        title: Text(l10n.accountMergeTitle),
        content: Text(l10n.accountMergeNoOtherAccounts),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(null),
            child: Text(l10n.dialogCancel),
          ),
        ],
      );
    }

    // Sort: same-name candidates first (most likely intent), preserving
    // original order within each bucket.
    final normalized = widget.source.displayName.trim().toLowerCase();
    final sameName = <Account>[];
    final others = <Account>[];
    for (final a in candidates) {
      if (a.displayName.trim().toLowerCase() == normalized) {
        sameName.add(a);
      } else {
        others.add(a);
      }
    }

    final ordered = [...sameName, ...others];

    // Auto-select the first same-name candidate to make the common case
    // one-click.
    if (_selectedTargetId == null && sameName.isNotEmpty) {
      _selectedTargetId = sameName.first.id;
    }

    return AlertDialog(
      title: Text(l10n.accountMergeTitle),
      content: SizedBox(
        width: double.maxFinite,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              l10n.accountMergePrompt(widget.source.displayName),
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              initialValue: _selectedTargetId,
              isExpanded: true,
              decoration: InputDecoration(
                labelText: l10n.accountMergeTargetLabel,
                border: const OutlineInputBorder(),
                isDense: true,
              ),
              items: [
                for (final a in ordered)
                  DropdownMenuItem(
                    value: a.id,
                    child: _AccountLabel(account: a, data: data),
                  ),
              ],
              onChanged: (v) => setState(() => _selectedTargetId = v),
            ),
          ],
        ),
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
              : Text(l10n.accountMergeConfirm),
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
    final credCount = account.credentials.length;
    final label = providerName.isNotEmpty
        ? '$providerName  ·  ${account.displayName}  ·  $credCount'
        : '${account.displayName}  ·  $credCount';
    return Text(label, overflow: TextOverflow.ellipsis);
  }
}
