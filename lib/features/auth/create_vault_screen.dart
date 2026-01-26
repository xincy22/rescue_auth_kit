import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/vault/vault_session.dart';

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
    setState(() {
      _error = null;
      _busy = true;
    });

    final p1 = _pw1.text;
    final p2 = _pw2.text;

    if (p1.length < 10) {
      setState(() {
        _busy = false;
        _error = 'Password too short (min 10 characters)';
      });
      return;
    }

    if (p1 != p2) {
      setState(() {
        _busy = false;
        _error = 'Passwords do not match';
      });
      return;
    }

    try {
      await context.read<VaultSession>().createNew(password: p1);
    } catch (e) {
      setState(() => _error = 'Failed to create vault: $e');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Create Vault')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            const Text(
              'Attention: Master password cannot be recovered. Make sure to remember it!',
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _pw1,
              obscureText: true,
              decoration: const InputDecoration(
                labelText: 'Master Password',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _pw2,
              obscureText: true,
              decoration: const InputDecoration(
                labelText: 'Confirm Password',
                border: OutlineInputBorder(),
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
                    : const Text('Create and Unlock'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
