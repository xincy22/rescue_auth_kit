import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/vault/vault_session.dart';
import '../../l10n/app_localizations.dart';

class CreateVaultScreen extends StatefulWidget {
  const CreateVaultScreen({super.key});

  @override
  State<CreateVaultScreen> createState() => _CreateVaultScreenState();
}

class _CreateVaultScreenState extends State<CreateVaultScreen> {
  final _pw1 = TextEditingController();
  final _pw2 = TextEditingController();

  bool _busy = false;
  String? _error;

  @override
  void dispose() {
    _pw1.dispose();
    _pw2.dispose();
    super.dispose();
  }

  Future<void> _create() async {
    final l10n = AppLocalizations.of(context);
    setState(() {
      _error = null;
      _busy = true;
    });

    final p1 = _pw1.text;
    final p2 = _pw2.text;

    if (p1.length < 10) {
      setState(() {
        _busy = false;
        _error = l10n.passwordMinLengthError;
      });
      return;
    }

    if (p1 != p2) {
      setState(() {
        _busy = false;
        _error = l10n.passwordMismatchError;
      });
      return;
    }

    try {
      await context.read<VaultSession>().createNew(password: p1);
    } catch (e) {
      setState(() => _error = l10n.createFailed(e.toString()));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(title: Text(l10n.createVaultTitle)),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Text(l10n.createWarning),
            const SizedBox(height: 16),
            TextField(
              controller: _pw1,
              obscureText: true,
              decoration: InputDecoration(
                labelText: l10n.masterPasswordLabel,
                border: const OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _pw2,
              obscureText: true,
              decoration: InputDecoration(
                labelText: l10n.confirmMasterPasswordLabel,
                border: const OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            if (_error != null)
              Text(
                _error!,
                style: TextStyle(color: Theme.of(context).colorScheme.error),
              ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: _busy ? null : _create,
                child: _busy
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : Text(l10n.createAndUnlockButton),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
