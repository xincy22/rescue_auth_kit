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
import '../../l10n/app_localizations.dart';

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
    final l10n = AppLocalizations.of(context);
    final ctrl = TextEditingController();
    final result = await showDialog<String?>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(title),
        content: TextField(
          controller: ctrl,
          obscureText: true,
          decoration: InputDecoration(
            labelText: l10n.masterPasswordLabel,
            border: const OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(l10n.dialogCancel),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, ctrl.text),
            child: Text(l10n.dialogContinue),
          ),
        ],
      ),
    );
    ctrl.dispose();
    return result;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final repo = context.read<VaultRepository>();

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l10n.backupCurrentPath,
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
                  label: Text(l10n.backupExport),
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
                            SnackBar(content: Text(l10n.backupExportShared)),
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
                              content: Text(l10n.backupExportedTo(loc.path)),
                            ),
                          );
                        }
                      }
                    } catch (e) {
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(l10n.backupExportFailed(e.toString())),
                          ),
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
                  label: Text(l10n.backupImport),
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
                          title: Text(l10n.backupImportReplaceTitle),
                          content: Text(l10n.backupImportReplaceBody),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.pop(ctx, false),
                              child: Text(l10n.dialogCancel),
                            ),
                            FilledButton(
                              onPressed: () => Navigator.pop(ctx, true),
                              child: Text(l10n.dialogContinue),
                            ),
                          ],
                        ),
                      );
                      if (ok != true) return;

                      if (!context.mounted) return;

                      final pw = await _askPassword(
                        context,
                        title: l10n.backupPasswordTitle,
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
                            content: Text(l10n.backupImportedFrom(file.name)),
                          ),
                        );
                      }
                    } on VaultAuthException {
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text(l10n.backupWrongPassword)),
                        );
                      }
                    } catch (e) {
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(l10n.backupImportFailed(e.toString())),
                          ),
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
