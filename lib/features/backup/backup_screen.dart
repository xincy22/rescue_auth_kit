import 'dart:io';

import 'package:file_selector/file_selector.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';

import '../../core/vault/vault_repository.dart';
import '../../core/vault/vault_session.dart';

class BackupScreen extends StatelessWidget {
  const BackupScreen({super.key});

  XTypeGroup _vaultTypeGroup() => const XTypeGroup(
    label: 'RescueAuthKit Vault',
    extensions: <String>['rakvault'],
  );

  String _suggestedFileName() {
    final now = DateTime.now();
    final stamp =
        '${now.year}${now.month.toString().padLeft(2, '0')}'
        '${now.day.toString().padLeft(2, '0')}-'
        '${now.hour.toString().padLeft(2, '0')}'
        '${now.minute.toString().padLeft(2, '0')}';
    return 'RescueAuthKit-$stamp.rakvault';
  }

  Future<String?> _askPassword(
    BuildContext context, {
    required String title,
  }) async {
    final ctrl = TextEditingController();
    final result = await showDialog<String?>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(title),
        content: TextField(
          controller: ctrl,
          obscureText: true,
          decoration: const InputDecoration(
            labelText: 'Password',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, ctrl.text),
            child: const Text('Confirm'),
          ),
        ],
      ),
    );
    ctrl.dispose();
    return result;
  }

  @override
  Widget build(BuildContext context) {
    final repo = context.read<VaultRepository>();

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Current Vault path: ',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 8),
          SelectableText(repo.vaultFilePath),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: FilledButton.icon(
                  icon: const Icon(Icons.upload),
                  label: const Text('Export Vault'),
                  onPressed: () async {
                    try {
                      final bytes = await repo.exportBytes();
                      final fileName = _suggestedFileName();

                      final isAndroid =
                          !kIsWeb &&
                          defaultTargetPlatform == TargetPlatform.android;

                      if (isAndroid) {
                        final tmp = await getTemporaryDirectory();
                        final outPath = p.join(tmp.path, fileName);
                        await File(outPath).writeAsBytes(bytes);

                        await SharePlus.instance.share(
                          ShareParams(
                            files: [XFile(outPath)],
                            text: 'RescueAuthKit Backup',
                          ),
                        );

                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text(
                                'File has been generated and shared',
                              ),
                            ),
                          );
                        }
                      } else {
                        final loc = await getSaveLocation(
                          suggestedName: fileName,
                        );
                        if (loc == null) return;

                        final xf = XFile.fromData(
                          bytes,
                          mimeType: 'application/octet-stream',
                          name: fileName,
                        );
                        await xf.saveTo(loc.path);

                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('Vault exported to ${loc.path}'),
                            ),
                          );
                        }
                      }
                    } catch (e) {
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Error exporting vault: $e')),
                        );
                      }
                    }
                  },
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: OutlinedButton.icon(
                  icon: const Icon(Icons.download),
                  label: const Text('Import Vault'),
                  onPressed: () async {
                    try {
                      final file = await openFile(
                        acceptedTypeGroups: <XTypeGroup>[_vaultTypeGroup()],
                      );
                      if (file == null) return;

                      if (!context.mounted) return;

                      final ok = await showDialog<bool>(
                        context: context,
                        builder: (ctx) => AlertDialog(
                          title: const Text(
                            'Import vault will replace the current vault',
                          ),
                          content: const Text(
                            'Sure you want to continue? (It is recommended that you export the current backup first)',
                          ),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.pop(ctx, false),
                              child: const Text('Cancel'),
                            ),
                            FilledButton(
                              onPressed: () => Navigator.pop(ctx, true),
                              child: const Text('Continue'),
                            ),
                          ],
                        ),
                      );
                      if (ok != true) return;

                      if (!context.mounted) return;

                      final pw = await _askPassword(
                        context,
                        title: 'Please enter the vault`s password',
                      );
                      if (pw == null || pw.isEmpty) return;

                      final bytes = Uint8List.fromList(
                        await file.readAsBytes(),
                      );

                      if (!context.mounted) return;

                      await context.read<VaultSession>().importVault(
                        vaultBytes: bytes,
                        password: pw,
                      );

                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Vault imported from ${file.name}'),
                          ),
                        );
                      }
                    } on VaultAuthException {
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('密码错误（或备份文件损坏）')),
                        );
                      }
                    } catch (e) {
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Error importing vault: $e')),
                        );
                      }
                    }
                  },
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
