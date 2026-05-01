import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/vault/vault_session.dart';
import '../../l10n/app_localizations.dart';
import '../developer/developer_screen.dart';
import '../recovery/recovery_screens.dart';
import '../scan/confirm_import_screen.dart';
import '../scan/paste_uri_dialog.dart';
import '../scan/scan_screen.dart';
import '../settings/settings_screen.dart';
import '../totp/totp_screen.dart';

enum _AddTotpAction { scan, paste }

enum _HomeDestination { totp, recovery, developer, settings }

class HomeShell extends StatefulWidget {
  const HomeShell({super.key});

  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> {
  _HomeDestination _selected = _HomeDestination.totp;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final developerEnabled = context
        .watch<VaultSession>()
        .data
        .developerSettings
        .enabled;
    final destinations =
        <
          ({
            _HomeDestination destination,
            IconData icon,
            String label,
            Widget page,
          })
        >[
          (
            destination: _HomeDestination.totp,
            icon: Icons.shield,
            label: l10n.tabTotp,
            page: const TotpScreen(),
          ),
          (
            destination: _HomeDestination.recovery,
            icon: Icons.key,
            label: l10n.tabRecovery,
            page: const RecoveryScreen(),
          ),
          if (developerEnabled)
            (
              destination: _HomeDestination.developer,
              icon: Icons.code,
              label: l10n.tabDeveloper,
              page: const DeveloperScreen(),
            ),
          (
            destination: _HomeDestination.settings,
            icon: Icons.settings,
            label: l10n.tabSettings,
            page: const SettingsScreen(),
          ),
        ];
    final selectedDestination =
        destinations.any((item) => item.destination == _selected)
        ? _selected
        : _HomeDestination.settings;
    final selectedIndex = destinations.indexWhere(
      (item) => item.destination == selectedDestination,
    );

    return Scaffold(
      appBar: AppBar(
        title: Text(destinations[selectedIndex].label),
        actions: [
          IconButton(
            tooltip: l10n.lockTooltip,
            onPressed: () => context.read<VaultSession>().lock(),
            icon: const Icon(Icons.lock),
          ),
        ],
      ),
      body: IndexedStack(
        index: selectedIndex,
        children: destinations.map((item) => item.page).toList(),
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: selectedIndex,
        onDestinationSelected: (index) =>
            setState(() => _selected = destinations[index].destination),
        destinations: destinations
            .map(
              (item) => NavigationDestination(
                icon: Icon(item.icon),
                label: item.label,
              ),
            )
            .toList(),
      ),
      floatingActionButton: _buildFab(context, selectedDestination),
    );
  }

  Widget? _buildFab(BuildContext context, _HomeDestination destination) {
    if (destination == _HomeDestination.totp) {
      return FloatingActionButton(
        onPressed: _addTotp,
        child: const Icon(Icons.add),
      );
    }
    if (destination == _HomeDestination.recovery) {
      return FloatingActionButton(
        onPressed: () => Navigator.of(
          context,
        ).push(MaterialPageRoute(builder: (_) => const AddRecoveryScreen())),
        child: const Icon(Icons.add),
      );
    }
    if (destination == _HomeDestination.developer) {
      return FloatingActionButton(
        onPressed: () => showAddDeveloperEntrySheet(context),
        child: const Icon(Icons.add),
      );
    }
    return null;
  }

  Future<void> _addTotp() async {
    final l10n = AppLocalizations.of(context);
    final isAndroid =
        !kIsWeb && defaultTargetPlatform == TargetPlatform.android;

    final action = await showModalBottomSheet<_AddTotpAction>(
      context: context,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (isAndroid)
              ListTile(
                leading: const Icon(Icons.qr_code_scanner),
                title: Text(l10n.addTotpSheetScan),
                onTap: () => Navigator.pop(ctx, _AddTotpAction.scan),
              ),
            ListTile(
              leading: const Icon(Icons.paste),
              title: Text(l10n.addTotpSheetPaste),
              onTap: () => Navigator.pop(ctx, _AddTotpAction.paste),
            ),
          ],
        ),
      ),
    );

    if (!mounted || action == null) return;

    String? uriText;

    if (action == _AddTotpAction.scan) {
      if (!mounted) return;
      uriText = await Navigator.of(
        context,
      ).push<String?>(MaterialPageRoute(builder: (_) => const ScanScreen()));
    } else {
      if (!mounted) return;
      uriText = await showPasteOtpauthDialog(context);
    }

    if (!mounted || uriText == null || uriText.trim().isEmpty) return;

    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => ConfirmImportScreen(otpauthUri: uriText!),
      ),
    );
  }
}
