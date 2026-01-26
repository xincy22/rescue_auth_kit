import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/vault/vault_session.dart';
import '../totp/totp_screen.dart';

class HomeShell extends StatefulWidget {
  const HomeShell({super.key});

  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> {
  int _index = 0;

  @override
  Widget build(BuildContext context) {
    final pages = const [
      TotpScreen(),
      Center(child: Text('Recovery')),
      Center(child: Text('Backup')),
    ];

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
    );
  }
}
