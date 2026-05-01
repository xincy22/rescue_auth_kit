import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:rescue_auth_kit/core/vault/vault_models.dart';
import 'package:rescue_auth_kit/core/vault/vault_repository.dart';
import 'package:rescue_auth_kit/core/vault/vault_session.dart';
import 'package:rescue_auth_kit/features/home/home_shell.dart';
import 'package:rescue_auth_kit/l10n/app_localizations.dart';

void main() {
  testWidgets('material smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(
      const MaterialApp(home: Scaffold(body: Text('smoke'))),
    );

    expect(find.text('smoke'), findsOneWidget);
  });

  testWidgets('settings switch shows and hides developer tab', (
    WidgetTester tester,
  ) async {
    final repo = VaultRepository.forPath(vaultFilePath: 'test-vault.rakvault');
    final session = _FakeVaultSession(repo);

    await tester.pumpWidget(
      MultiProvider(
        providers: [
          Provider<VaultRepository>.value(value: repo),
          ChangeNotifierProvider<VaultSession>.value(value: session),
        ],
        child: const MaterialApp(
          localizationsDelegates: [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          supportedLocales: [Locale('en'), Locale('zh')],
          home: HomeShell(),
        ),
      ),
    );

    expect(find.text('Developer'), findsNothing);
    await tester.tap(find.text('Settings').last);
    await tester.pump(const Duration(milliseconds: 100));

    await tester.tap(find.text('Developer Backup'));
    await tester.pump(const Duration(milliseconds: 100));
    expect(find.text('Developer'), findsOneWidget);

    await tester.tap(find.text('Developer Backup'));
    await tester.pump(const Duration(milliseconds: 100));
    expect(find.text('Developer'), findsNothing);
  });
}

class _FakeVaultSession extends VaultSession {
  _FakeVaultSession(super.repo);

  VaultData _data = VaultData.empty();

  @override
  VaultData get data => _data;

  @override
  bool get isUnlocked => true;

  @override
  Future<void> setDeveloperBackupEnabled(bool enabled) async {
    _data = _data.copyWith(
      developerSettings: _data.developerSettings.copyWith(enabled: enabled),
    );
    notifyListeners();
  }
}
