import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/vault/vault_models.dart';
import '../../core/vault/vault_session.dart';
import '../../l10n/app_localizations.dart';
import 'accounts_list_screen.dart';

/// The top-level home-tab screen: lists all [ServiceProvider]s.
///
/// Tapping a row navigates to [AccountsListScreen] filtered to that provider.
/// Never renders live TOTP digits or recovery codes.
class ProvidersListScreen extends StatelessWidget {
  const ProvidersListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final session = context.watch<VaultSession>();
    final providers = session.data.providers;

    if (providers.isEmpty) {
      return Center(child: Text(l10n.providersListEmpty));
    }

    return ListView.separated(
      padding: const EdgeInsets.all(12),
      itemCount: providers.length,
      separatorBuilder: (_, _) => const SizedBox(height: 8),
      itemBuilder: (context, index) {
        final p = providers[index];
        final accountsUnder =
            session.data.accountsOf(p.id).toList(growable: false);
        return _ProviderCard(provider: p, accounts: accountsUnder);
      },
    );
  }
}

class _ProviderCard extends StatelessWidget {
  const _ProviderCard({required this.provider, required this.accounts});

  final ServiceProvider provider;
  final List<Account> accounts;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final hasAnyTotp = accounts.any((a) => a.hasTotp);
    final hasAnyRecovery = accounts.any((a) => a.hasRecoveryCodes);

    return Card(
      child: ListTile(
        title: Text(provider.name),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              l10n.providersListAccountCount(accounts.length),
              style: Theme.of(context).textTheme.bodySmall,
            ),
            if (hasAnyTotp || hasAnyRecovery)
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Wrap(
                  spacing: 6,
                  children: [
                    if (hasAnyTotp)
                      _Badge(
                        label: l10n.accountsBadgeTotp,
                        icon: Icons.shield,
                      ),
                    if (hasAnyRecovery)
                      _Badge(
                        label: l10n.accountsBadgeRecovery,
                        icon: Icons.key,
                      ),
                  ],
                ),
              ),
          ],
        ),
        trailing: const Icon(Icons.chevron_right),
        onTap: () => Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => AccountsListScreen(providerId: provider.id),
          ),
        ),
      ),
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
