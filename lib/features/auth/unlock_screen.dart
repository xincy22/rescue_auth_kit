import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/vault/vault_repository.dart';
import '../../core/vault/vault_session.dart';
import '../../l10n/app_localizations.dart';

class UnlockScreen extends StatefulWidget {
  const UnlockScreen({super.key});

  @override
  State<UnlockScreen> createState() => _UnlockScreenState();
}

class _UnlockScreenState extends State<UnlockScreen> {
  final _pw = TextEditingController();
  bool _busy = false;
  String? _error;

  @override
  void dispose() {
    _pw.dispose();
    super.dispose();
  }

  Future<void> _unlock() async {
    final l10n = AppLocalizations.of(context);
    setState(() {
      _busy = true;
      _error = null;
    });

    try {
      await context.read<VaultSession>().unlock(password: _pw.text);
    } on VaultAuthException {
      setState(() => _error = l10n.incorrectPassword);
    } catch (e) {
      setState(() => _error = l10n.unlockFailed(e.toString()));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(title: Text(l10n.unlockVaultTitle)),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            TextField(
              controller: _pw,
              obscureText: true,
              decoration: InputDecoration(
                labelText: l10n.masterPasswordLabel,
                border: const OutlineInputBorder(),
              ),
              onSubmitted: (_) => _busy ? null : _unlock(),
            ),
            const SizedBox(height: 12),
            if (_error != null)
              Text(
                _error!,
                style: TextStyle(color: Theme.of(context).colorScheme.error),
              ),
            if (_error != null) const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: _busy ? null : _unlock,
                child: _busy
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : Text(l10n.unlockButton),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
