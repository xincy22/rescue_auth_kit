import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/vault/vault_session.dart';
import '../recovery/recovery_screens.dart';
import '../scan/confirm_import_screen.dart';
import '../scan/paste_uri_dialog.dart';
import '../scan/scan_screen.dart';
import '../totp/totp_screen.dart';
import '../backup/backup_screen.dart';

enum _AddTotpAction { scan, paste }

class HomeShell extends StatefulWidget {
  const HomeShell({super.key});

  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> {
  int _index = 0;

  @override
  Widget build(BuildContext context) {
    final pages = const [TotpScreen(), RecoveryScreen(), BackupScreen()];

    final titles = const ['TOTP', 'Recovery', 'Backup'];

    return Scaffold(
      appBar: AppBar(
        title: Text(titles[_index]),
        actions: [
          IconButton(
            tooltip: 'Lock Vault',
            onPressed: () => context.read<VaultSession>().lock(),
            icon: const Icon(Icons.lock),
          ),
        ],
      ),
      body: IndexedStack(index: _index, children: pages),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: (index) => setState(() => _index = index),
        destinations: const [
          NavigationDestination(icon: Icon(Icons.shield), label: 'TOTP'),
          NavigationDestination(icon: Icon(Icons.key), label: 'Recovery'),
          NavigationDestination(
            icon: Icon(Icons.import_export),
            label: 'Backup',
          ),
        ],
      ),
      floatingActionButton: _buildFab(context),
    );
  }

  Widget? _buildFab(BuildContext context) {
    if (_index == 0) {
      return FloatingActionButton(
        onPressed: _addTotp,
        child: const Icon(Icons.add),
      );
    }
    if (_index == 1) {
      return FloatingActionButton(
        onPressed: () => Navigator.of(
          context,
        ).push(MaterialPageRoute(builder: (_) => const AddRecoveryScreen())),
        child: const Icon(Icons.add),
      );
    }
    return null;
  }

  Future<void> _addTotp() async {
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
                title: const Text('Scan QR'),
                onTap: () => Navigator.pop(ctx, _AddTotpAction.scan),
              ),
            ListTile(
              leading: const Icon(Icons.paste),
              title: const Text('Paste otpauth URI'),
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
      uriText = await Navigator.of(context).push<String?>(
        MaterialPageRoute(builder: (_) => const ScanScreen()),
      );
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
