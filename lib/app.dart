import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:provider/provider.dart';

import 'core/vault/vault_repository.dart';
import 'core/vault/vault_session.dart';
import 'features/auth/create_vault_screen.dart';
import 'features/auth/unlock_screen.dart';
import 'features/home/home_shell.dart';
import 'l10n/app_localizations.dart';

class RescueAuthKitApp extends StatelessWidget {
  const RescueAuthKitApp({super.key, required this.vaultRepository});

  final VaultRepository vaultRepository;

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        Provider<VaultRepository>.value(value: vaultRepository),
        ChangeNotifierProvider<VaultSession>(
          create: (_) => VaultSession(vaultRepository),
        ),
      ],
      child: MaterialApp(
        theme: ThemeData(
          useMaterial3: true,
          colorSchemeSeed: Colors.indigo,
          fontFamilyFallback: const [
            'Microsoft YaHei UI',
            'Microsoft YaHei',
            'PingFang SC',
            'Noto Sans CJK SC',
            'Noto Sans SC',
          ],
        ),
        localizationsDelegates: const [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: const [
          Locale('en'),
          Locale('zh'),
        ],
        onGenerateTitle: (context) => AppLocalizations.of(context).appTitle,
        home: const RootGate(),
      ),
    );
  }
}

class RootGate extends StatelessWidget {
  const RootGate({super.key});

  @override
  Widget build(BuildContext context) {
    final session = context.watch<VaultSession>();
    final repo = context.read<VaultRepository>();

    if (session.isUnlocked) {
      return const HomeShell();
    }

    return FutureBuilder<bool>(
      future: repo.vaultFileExists(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const _Splash();
        }
        final exists = snapshot.data!;
        return exists ? const UnlockScreen() : const CreateVaultScreen();
      },
    );
  }
}

class _Splash extends StatelessWidget {
  const _Splash();

  @override
  Widget build(BuildContext context) {
    return const Scaffold(body: Center(child: CircularProgressIndicator()));
  }
}
