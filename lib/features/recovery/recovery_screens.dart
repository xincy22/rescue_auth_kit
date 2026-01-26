import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../core/vault/vault_session.dart';

class RecoveryScreen extends StatelessWidget {
  const RecoveryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final session = context.watch<VaultSession>();
    final sets = session.data.recoveryCodeSets;

    if (sets.isEmpty) {
      return const Center(child: Text('No recovery codes yet. Tap + to add.'));
    }

    return ListView.separated(
      padding: const EdgeInsets.all(12),
      itemCount: sets.length,
      separatorBuilder: (_, __) => const SizedBox(height: 8),
      itemBuilder: (context, index) {
        final s = sets[index];
        return Card(
          child: ListTile(
            title: Text(s.title.isEmpty ? '(No title)' : s.title),
            subtitle: Text('${s.codes.length} codes'),
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => RecoveryDetailScreen(setId: s.id),
              ),
            ),
            trailing: IconButton(
              tooltip: 'Delete',
              icon: const Icon(Icons.delete_outline),
              onPressed: () async {
                final ok = await showDialog<bool>(
                  context: context,
                  builder: (ctx) => AlertDialog(
                    title: const Text('Delete this recovery set?'),
                    content: Text(s.title.isEmpty ? '(No title)' : s.title),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(ctx, false),
                        child: const Text('Cancel'),
                      ),
                      FilledButton(
                        onPressed: () => Navigator.pop(ctx, true),
                        child: const Text('Delete'),
                      ),
                    ],
                  ),
                );
                if (ok == true) {
                  await context.read<VaultSession>().removeRecoverySet(s.id);
                }
              },
            ),
          ),
        );
      },
    );
  }
}

class RecoveryDetailScreen extends StatelessWidget {
  const RecoveryDetailScreen({super.key, required this.setId});

  final String setId;

  @override
  Widget build(BuildContext context) {
    final session = context.watch<VaultSession>();
    final set = session.data.recoveryCodeSets.firstWhere((e) => e.id == setId);

    return Scaffold(
      appBar: AppBar(
        title: Text(set.title.isEmpty ? '(No title)' : set.title),
        actions: [
          IconButton(
            tooltip: 'Copy all',
            icon: const Icon(Icons.copy),
            onPressed: () async {
              final all = set.codes.join('\n');
              await Clipboard.setData(ClipboardData(text: all));
              if (!context.mounted) return;
              ScaffoldMessenger.of(
                context,
              ).showSnackBar(const SnackBar(content: Text('Copied')));
            },
          ),
        ],
      ),
      body: ListView.separated(
        padding: const EdgeInsets.all(12),
        itemCount: set.codes.length,
        separatorBuilder: (_, __) => const Divider(),
        itemBuilder: (context, index) {
          final code = set.codes[index];
          return ListTile(
            title: Text(code),
            trailing: IconButton(
              tooltip: 'Copy',
              icon: const Icon(Icons.copy),
              onPressed: () async {
                await Clipboard.setData(ClipboardData(text: code));
                if (!context.mounted) return;
                ScaffoldMessenger.of(
                  context,
                ).showSnackBar(const SnackBar(content: Text('Copied')));
              },
            ),
          );
        },
      ),
    );
  }
}

class AddRecoveryScreen extends StatefulWidget {
  const AddRecoveryScreen({super.key});

  @override
  State<AddRecoveryScreen> createState() => _AddRecoveryScreenState();
}

class _AddRecoveryScreenState extends State<AddRecoveryScreen> {
  final _titleCtrl = TextEditingController();
  final _codesCtrl = TextEditingController();

  bool _saving = false;
  String? _error;

  @override
  void dispose() {
    _titleCtrl.dispose();
    _codesCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    setState(() {
      _saving = true;
      _error = null;
    });

    final title = _titleCtrl.text.trim();
    final codes = _codesCtrl.text
        .split(RegExp(r'[\r\n]+'))
        .map((e) => e.trim())
        .where((e) => e.isNotEmpty)
        .toList(growable: false);

    if (codes.isEmpty) {
      setState(() {
        _saving = false;
        _error = 'Please enter at least one code.';
      });
      return;
    }

    try {
      await context.read<VaultSession>().addRecoverySet(
        title: title,
        codes: codes,
      );
      if (!mounted) return;
      Navigator.of(context).pop();
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Recovery codes saved')));
    } catch (e) {
      setState(() => _error = 'Save failed: $e');
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Add Recovery Codes')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            TextField(
              controller: _titleCtrl,
              decoration: const InputDecoration(
                labelText: 'Title (optional)',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _codesCtrl,
              minLines: 6,
              maxLines: 12,
              decoration: const InputDecoration(
                labelText: 'Recovery Codes (one per line)',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            if (_error != null)
              Text(
                _error!,
                style: TextStyle(color: Theme.of(context).colorScheme.error),
              ),
            const Spacer(),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: _saving ? null : _save,
                child: _saving
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text('Save'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
