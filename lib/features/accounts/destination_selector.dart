import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/vault/vault_models.dart';
import '../../core/vault/vault_session.dart';
import '../../l10n/app_localizations.dart';

/// Where a freshly-built [Credential] draft should land.
sealed class CredentialDestination {
  const CredentialDestination();

  /// Whether enough information has been collected to persist.
  bool get isComplete;
}

/// Append the credential to an already-existing account.
class DestinationExistingAccount extends CredentialDestination {
  const DestinationExistingAccount({required this.accountId});
  final String accountId;
  @override
  bool get isComplete => accountId.isNotEmpty;
}

/// Create a new account under an existing provider, then save.
class DestinationNewAccountUnderProvider extends CredentialDestination {
  const DestinationNewAccountUnderProvider({
    required this.providerId,
    required this.accountDisplayName,
  });
  final String providerId;
  final String accountDisplayName;
  @override
  bool get isComplete =>
      providerId.isNotEmpty && accountDisplayName.trim().isNotEmpty;
}

/// Create a brand-new provider AND a brand-new account, then save.
class DestinationNewProviderAndAccount extends CredentialDestination {
  const DestinationNewProviderAndAccount({
    required this.providerName,
    required this.accountDisplayName,
  });
  final String providerName;
  final String accountDisplayName;
  @override
  bool get isComplete =>
      providerName.trim().isNotEmpty && accountDisplayName.trim().isNotEmpty;
}

/// An inline form section that lets the user pick where to save a credential
/// before they hit Save. Three modes:
///
///   1. Existing account            (pick from a search list)
///   2. Existing provider + new acc (pick provider, enter account name)
///   3. Brand-new provider+account  (enter both)
///
/// When a [lockedProviderId] or [lockedAccountId] is supplied, the selector
/// renders as read-only — the user already knows where it's going.
class DestinationSelector extends StatefulWidget {
  const DestinationSelector({
    super.key,
    required this.onChanged,
    this.providerNameHint,
    this.accountNameHint,
    this.lockedProviderId,
    this.lockedAccountId,
  });

  final ValueChanged<CredentialDestination?> onChanged;

  /// Pre-fill for the provider-name field (typically the otpauth issuer).
  final String? providerNameHint;

  /// Pre-fill for the account-name field (typically the otpauth account name
  /// or recovery-codes title).
  final String? accountNameHint;

  /// If non-null, locks the selector to "new account under this provider".
  final String? lockedProviderId;

  /// If non-null, locks the selector to "this account" (no other modes shown).
  final String? lockedAccountId;

  @override
  State<DestinationSelector> createState() => _DestinationSelectorState();
}

enum _Mode { newProvider, existingProvider, existingAccount }

class _DestinationSelectorState extends State<DestinationSelector> {
  late _Mode _mode;
  late final TextEditingController _providerNameCtrl;
  late final TextEditingController _accountNameCtrl;
  String? _selectedProviderId;
  String? _selectedAccountId;

  @override
  void initState() {
    super.initState();
    _providerNameCtrl =
        TextEditingController(text: widget.providerNameHint ?? '');
    _accountNameCtrl =
        TextEditingController(text: widget.accountNameHint ?? '');
    _providerNameCtrl.addListener(_emit);
    _accountNameCtrl.addListener(_emit);

    if (widget.lockedAccountId != null) {
      _mode = _Mode.existingAccount;
      _selectedAccountId = widget.lockedAccountId;
    } else if (widget.lockedProviderId != null) {
      _mode = _Mode.existingProvider;
      _selectedProviderId = widget.lockedProviderId;
    } else {
      // Default mode is decided in build() once we can read the session,
      // because we want "existingProvider" by default when providers exist.
      _mode = _Mode.newProvider;
    }
    // Initial emit happens after first build via _emit() listeners.
    WidgetsBinding.instance.addPostFrameCallback((_) => _emit());
  }

  @override
  void dispose() {
    _providerNameCtrl.dispose();
    _accountNameCtrl.dispose();
    super.dispose();
  }

  void _emit() {
    final current = _currentDestination();
    widget.onChanged(current);
  }

  CredentialDestination? _currentDestination() {
    switch (_mode) {
      case _Mode.existingAccount:
        final id = _selectedAccountId;
        if (id == null || id.isEmpty) return null;
        return DestinationExistingAccount(accountId: id);
      case _Mode.existingProvider:
        final providerId = _selectedProviderId;
        if (providerId == null || providerId.isEmpty) return null;
        return DestinationNewAccountUnderProvider(
          providerId: providerId,
          accountDisplayName: _accountNameCtrl.text,
        );
      case _Mode.newProvider:
        return DestinationNewProviderAndAccount(
          providerName: _providerNameCtrl.text,
          accountDisplayName: _accountNameCtrl.text,
        );
    }
  }

  void _setMode(_Mode m) {
    if (_mode == m) return;
    setState(() {
      _mode = m;
      if (m != _Mode.existingAccount) _selectedAccountId = null;
    });
    _emit();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final session = context.watch<VaultSession>();
    final data = session.data;

    // -----------------------------------------------------------------
    // Locked variants — render read-only summary.
    // -----------------------------------------------------------------
    if (widget.lockedAccountId != null) {
      final account = data.accounts
          .where((a) => a.id == widget.lockedAccountId)
          .toList();
      if (account.isEmpty) return const SizedBox.shrink();
      final a = account.single;
      ServiceProvider? provider;
      try {
        provider = data.requireProvider(a.providerId);
      } catch (_) {}
      return _LockedSummary(
        providerName: provider?.name ?? '—',
        accountName: a.displayName,
        labelText: l10n.destinationLockedToAccount,
      );
    }

    // -----------------------------------------------------------------
    // First-build default mode adjustment.
    // If user has no providers at all, only the "new provider" mode makes
    // sense, so force it. Otherwise default to "existing provider".
    // -----------------------------------------------------------------
    if (widget.lockedProviderId == null && data.providers.isEmpty) {
      // Already on newProvider in initState; keep it.
    } else if (widget.lockedProviderId == null && _mode == _Mode.newProvider) {
      // We initialized to newProvider blindly. If providers exist and the
      // user hasn't typed anything yet, gently nudge to existingProvider.
      if (_providerNameCtrl.text == (widget.providerNameHint ?? '') &&
          _accountNameCtrl.text == (widget.accountNameHint ?? '') &&
          _selectedProviderId == null &&
          data.providers.isNotEmpty) {
        // Stay in newProvider — not overriding user-visible default would be
        // surprising. Most existing apps default to "create new" for fresh
        // imports; we honor that.
      }
    }

    // -----------------------------------------------------------------
    // Mode toggle (hidden when locked to a provider).
    // -----------------------------------------------------------------
    final segments = <ButtonSegment<_Mode>>[
      ButtonSegment(
        value: _Mode.newProvider,
        label: Text(l10n.pickerModeNewProvider),
      ),
      if (data.providers.isNotEmpty)
        ButtonSegment(
          value: _Mode.existingProvider,
          label: Text(l10n.pickerModeExistingProvider),
        ),
      if (data.accounts.isNotEmpty)
        ButtonSegment(
          value: _Mode.existingAccount,
          label: Text(l10n.pickerModeExistingAccount),
        ),
    ];

    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              l10n.destinationSelectorTitle,
              style: Theme.of(context).textTheme.titleSmall,
            ),
            const SizedBox(height: 8),
            if (widget.lockedProviderId == null && segments.length > 1)
              SegmentedButton<_Mode>(
                segments: segments,
                selected: {_mode},
                onSelectionChanged: (s) => _setMode(s.first),
              ),
            if (widget.lockedProviderId == null && segments.length > 1)
              const SizedBox(height: 12),
            switch (_mode) {
              _Mode.newProvider => _buildNewProvider(l10n),
              _Mode.existingProvider =>
                _buildExistingProvider(l10n, data, locked: false),
              _Mode.existingAccount => _buildExistingAccount(l10n, data),
            },
          ],
        ),
      ),
    );
  }

  Widget _buildNewProvider(AppLocalizations l10n) {
    return Column(
      children: [
        TextField(
          controller: _providerNameCtrl,
          decoration: InputDecoration(
            labelText: l10n.providerNameLabel,
            border: const OutlineInputBorder(),
            isDense: true,
          ),
          textInputAction: TextInputAction.next,
        ),
        const SizedBox(height: 8),
        TextField(
          controller: _accountNameCtrl,
          decoration: InputDecoration(
            labelText: l10n.accountLabel,
            border: const OutlineInputBorder(),
            isDense: true,
          ),
          textInputAction: TextInputAction.done,
        ),
      ],
    );
  }

  Widget _buildExistingProvider(
    AppLocalizations l10n,
    VaultData data, {
    required bool locked,
  }) {
    final providers = data.providers;
    final lockedId = widget.lockedProviderId;
    final selectedId = lockedId ?? _selectedProviderId;

    return Column(
      children: [
        if (lockedId != null)
          _LockedSummary(
            providerName: providers
                .firstWhere(
                  (p) => p.id == lockedId,
                  orElse: () => ServiceProvider(
                    id: lockedId,
                    name: '—',
                    createdAt: DateTime.now(),
                    updatedAt: DateTime.now(),
                  ),
                )
                .name,
            accountName: null,
            labelText: l10n.destinationLockedToProvider,
          )
        else
          DropdownButtonFormField<String>(
            initialValue: selectedId,
            decoration: InputDecoration(
              labelText: l10n.providerNameLabel,
              border: const OutlineInputBorder(),
              isDense: true,
            ),
            items: [
              for (final p in providers)
                DropdownMenuItem(value: p.id, child: Text(p.name)),
            ],
            onChanged: (v) {
              setState(() => _selectedProviderId = v);
              _emit();
            },
          ),
        const SizedBox(height: 8),
        TextField(
          controller: _accountNameCtrl,
          decoration: InputDecoration(
            labelText: l10n.accountLabel,
            border: const OutlineInputBorder(),
            isDense: true,
          ),
          textInputAction: TextInputAction.done,
        ),
      ],
    );
  }

  Widget _buildExistingAccount(AppLocalizations l10n, VaultData data) {
    final accounts = data.accounts;

    return DropdownButtonFormField<String>(
      initialValue: _selectedAccountId,
      decoration: InputDecoration(
        labelText: l10n.pickerModeExistingAccount,
        border: const OutlineInputBorder(),
        isDense: true,
      ),
      isExpanded: true,
      items: [
        for (final a in accounts)
          DropdownMenuItem(
            value: a.id,
            child: _AccountDropdownLabel(account: a, data: data),
          ),
      ],
      onChanged: (v) {
        setState(() => _selectedAccountId = v);
        _emit();
      },
    );
  }
}

class _AccountDropdownLabel extends StatelessWidget {
  const _AccountDropdownLabel({required this.account, required this.data});

  final Account account;
  final VaultData data;

  @override
  Widget build(BuildContext context) {
    String providerName = '';
    try {
      providerName = data.requireProvider(account.providerId).name;
    } catch (_) {}
    return Row(
      children: [
        Flexible(
          child: Text(
            providerName.isNotEmpty
                ? '$providerName  ·  ${account.displayName}'
                : account.displayName,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}

class _LockedSummary extends StatelessWidget {
  const _LockedSummary({
    required this.providerName,
    required this.accountName,
    required this.labelText,
  });

  final String providerName;
  final String? accountName;
  final String labelText;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          const Icon(Icons.lock_outline, size: 18),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  labelText,
                  style: Theme.of(context).textTheme.labelSmall,
                ),
                const SizedBox(height: 2),
                Text(
                  accountName != null
                      ? '$providerName  ·  $accountName'
                      : providerName,
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Persists a [draft] credential to [destination] via the given session.
///
/// Returns nothing; throws on failure (caller is expected to catch and
/// surface the error).
Future<void> persistDestination({
  required VaultSession session,
  required Credential draft,
  required CredentialDestination destination,
}) async {
  switch (destination) {
    case DestinationExistingAccount(:final accountId):
      await session.addCredentialToAccount(
        accountId: accountId,
        draft: draft,
      );
    case DestinationNewAccountUnderProvider(
        :final providerId,
        :final accountDisplayName,
      ):
      await session.addCredentialAsNewAccount(
        providerId: providerId,
        displayName: accountDisplayName,
        draft: draft,
      );
    case DestinationNewProviderAndAccount(
        :final providerName,
        :final accountDisplayName,
      ):
      await session.addCredentialAsNewProviderAndAccount(
        providerName: providerName,
        accountDisplayName: accountDisplayName,
        draft: draft,
      );
  }
}
