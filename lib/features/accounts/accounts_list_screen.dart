import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/vault/vault_models.dart';
import '../../core/vault/vault_session.dart';
import '../../l10n/app_localizations.dart';
import 'account_detail_screen.dart';
import 'add_credential_sheet.dart';
import 'merge_account_dialog.dart';
import 'move_account_dialog.dart';

/// Lists all [Account]s belonging to a single [ServiceProvider].
///
/// Pushed from [ProvidersListScreen] when the user taps a provider row.
/// Never renders live TOTP digits or recovery codes — only credential-kind
/// badges per account.
class AccountsListScreen extends StatelessWidget {
  const AccountsListScreen({super.key, required this.providerId});

  final String providerId;

  Future<void> _showProviderMenu(
    BuildContext context,
    ServiceProvider provider,
  ) async {
    final l10n = AppLocalizations.of(context);
    final action = await showModalBottomSheet<String>(
      context: context,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.edit),
              title: Text(l10n.providerRename),
              onTap: () => Navigator.of(ctx).pop('rename'),
            ),
            ListTile(
              leading: Icon(
                Icons.delete_outline,
                color: Theme.of(ctx).colorScheme.error,
              ),
              title: Text(
                l10n.providerDelete,
                style: TextStyle(
                  color: Theme.of(ctx).colorScheme.error,
                ),
              ),
              onTap: () => Navigator.of(ctx).pop('delete'),
            ),
          ],
        ),
      ),
    );

    if (!context.mounted) return;
    if (action == 'rename') {
      await _renameProvider(context, provider);
    } else if (action == 'delete') {
      await _confirmDeleteProvider(context, provider);
    }
  }

  Future<void> _renameProvider(
    BuildContext context,
    ServiceProvider provider,
  ) async {
    final l10n = AppLocalizations.of(context);
    final controller = TextEditingController(text: provider.name);

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.providerRename),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: InputDecoration(labelText: l10n.providerNameLabel),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(l10n.dialogCancel),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(l10n.dialogContinue),
          ),
        ],
      ),
    );

    if (!context.mounted || confirmed != true) return;
    final name = controller.text.trim();
    if (name.isEmpty) return;
    await context.read<VaultSession>().renameProvider(
          providerId: providerId,
          name: name,
        );
  }

  Future<void> _confirmDeleteProvider(
    BuildContext context,
    ServiceProvider provider,
  ) async {
    final l10n = AppLocalizations.of(context);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.providerDelete),
        content: Text(l10n.providerDeleteConfirm(provider.name)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(l10n.dialogCancel),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(ctx).colorScheme.error,
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(l10n.deleteButton),
          ),
        ],
      ),
    );

    if (!context.mounted || confirmed != true) return;
    await context.read<VaultSession>().removeProvider(providerId);
    if (!context.mounted) return;
    Navigator.of(context).pop();
  }

  Future<void> _renameAccount(
    BuildContext context,
    Account account,
  ) async {
    final l10n = AppLocalizations.of(context);
    final controller = TextEditingController(text: account.displayName);

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.accountDetailRename),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: InputDecoration(labelText: l10n.accountLabel),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(l10n.dialogCancel),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(l10n.dialogContinue),
          ),
        ],
      ),
    );

    if (!context.mounted || confirmed != true) return;
    final displayName = controller.text.trim();
    if (displayName.isEmpty) return;
    await context.read<VaultSession>().renameAccount(
          accountId: account.id,
          displayName: displayName,
        );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final session = context.watch<VaultSession>();

    final providerExists =
        session.data.providers.any((p) => p.id == providerId);
    if (!providerExists) {
      // Provider was deleted externally; pop after frame.
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (Navigator.of(context).canPop()) Navigator.of(context).pop();
      });
      return const Scaffold(body: SizedBox.shrink());
    }

    final provider = session.data.requireProvider(providerId);
    final accounts =
        session.data.accountsOf(providerId).toList(growable: false);

    return Scaffold(
      appBar: AppBar(
        title: Text(provider.name),
        actions: [
          IconButton(
            tooltip: l10n.providerActions,
            icon: const Icon(Icons.more_vert),
            onPressed: () => _showProviderMenu(context, provider),
          ),
        ],
      ),
      body: accounts.isEmpty
          ? Center(child: Text(l10n.accountsListEmpty))
          : ListView.separated(
              padding: const EdgeInsets.all(12),
              itemCount: accounts.length,
              separatorBuilder: (_, _) => const SizedBox(height: 8),
              itemBuilder: (context, index) {
                final a = accounts[index];
                return Card(
                  child: ListTile(
                    title: Text(a.displayName),
                    subtitle: _CredentialBadgesRow(account: a),
                    trailing: PopupMenuButton<String>(
                      onSelected: (value) {
                        if (value == 'rename') {
                          _renameAccount(context, a);
                        } else if (value == 'move') {
                          showMoveAccountDialog(context, account: a);
                        } else if (value == 'merge') {
                          showMergeAccountDialog(context, source: a);
                        }
                      },
                      itemBuilder: (ctx) => [
                        PopupMenuItem(
                          value: 'rename',
                          child: Text(l10n.accountDetailRename),
                        ),
                        PopupMenuItem(
                          value: 'move',
                          child: Text(l10n.accountMoveAction),
                        ),
                        PopupMenuItem(
                          value: 'merge',
                          child: Text(l10n.accountMergeAction),
                        ),
                      ],
                    ),
                    onTap: () => Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) =>
                            AccountDetailScreen(accountId: a.id),
                      ),
                    ),
                  ),
                );
              },
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => AddCredentialSheet.show(
          context,
          targetProviderId: providerId,
        ),
        child: const Icon(Icons.add),
      ),
    );
  }
}

class _CredentialBadgesRow extends StatelessWidget {
  const _CredentialBadgesRow({required this.account});

  final Account account;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final badges = <Widget>[];

    if (account.hasTotp) {
      badges.add(_Badge(label: l10n.accountsBadgeTotp, icon: Icons.shield));
    }
    if (account.hasRecoveryCodes) {
      badges.add(_Badge(label: l10n.accountsBadgeRecovery, icon: Icons.key));
    }

    if (badges.isEmpty) {
      return Text(
        l10n.accountDetailEmptyState,
        style: Theme.of(context).textTheme.bodySmall,
      );
    }

    return Padding(
      padding: const EdgeInsets.only(top: 4),
      child: Wrap(spacing: 6, children: badges),
    );
  }
}

class _Badge extends StatelessWidget {
  const _Badge({required this.label, required this.icon});

  final String label;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: colorScheme.secondaryContainer,
        borderRadius: BorderRadius.circular(4),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: colorScheme.onSecondaryContainer),
          const SizedBox(width: 3),
          Text(
            label,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: colorScheme.onSecondaryContainer,
            ),
          ),
        ],
      ),
    );
  }
}
