import 'dart:io';

import 'package:file_selector/file_selector.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/update/update_checker.dart';
import '../../core/vault/vault_repository.dart';
import '../../core/vault/vault_session.dart';
import '../../l10n/app_localizations.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  late final Future<PackageInfo?> _packageInfoFuture;

  @override
  void initState() {
    super.initState();
    _packageInfoFuture = _loadPackageInfo();
  }

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
    final developerEnabled = context
        .watch<VaultSession>()
        .data
        .developerSettings
        .enabled;

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Text(
          l10n.settingsVaultSection,
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: 8),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(l10n.backupCurrentPath),
                const SizedBox(height: 8),
                SelectableText(repo.vaultFilePath),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: FilledButton.icon(
                        icon: const Icon(Icons.upload),
                        label: Text(l10n.backupExport),
                        onPressed: () => _exportVault(context, repo),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: OutlinedButton.icon(
                        icon: const Icon(Icons.download),
                        label: Text(l10n.backupImport),
                        onPressed: () => _importVault(context),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        Text(
          l10n.settingsFeaturesSection,
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: 8),
        Card(
          child: SwitchListTile(
            secondary: const Icon(Icons.code),
            title: Text(l10n.settingsDeveloperBackupTitle),
            subtitle: Text(l10n.settingsDeveloperBackupSubtitle),
            value: developerEnabled,
            onChanged: (value) async {
              await context.read<VaultSession>().setDeveloperBackupEnabled(
                value,
              );
            },
          ),
        ),
        const SizedBox(height: 16),
        _buildVersionSection(context),
      ],
    );
  }

  Future<PackageInfo?> _loadPackageInfo() async {
    try {
      return await PackageInfo.fromPlatform();
    } catch (_) {
      return null;
    }
  }

  Widget _buildVersionSection(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          l10n.settingsVersionSection,
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: 8),
        Card(
          child: ListTile(
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 12,
            ),
            leading: const Icon(Icons.info_outline),
            title: Text(l10n.settingsVersionTitle),
            subtitle: FutureBuilder<PackageInfo?>(
              future: _packageInfoFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return Text(l10n.settingsLoadingVersion);
                }

                final packageInfo = snapshot.data;
                final version = packageInfo == null
                    ? l10n.settingsUnknownVersion
                    : '${packageInfo.version}+${packageInfo.buildNumber}';

                return Text(l10n.settingsAppVersion(version));
              },
            ),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const VersionInfoScreen()),
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _exportVault(BuildContext context, VaultRepository repo) async {
    final l10n = AppLocalizations.of(context);

    try {
      final bytes = await repo.exportBytes();
      final fileName = _suggestedFileName();

      final isAndroid =
          !kIsWeb && defaultTargetPlatform == TargetPlatform.android;

      if (isAndroid) {
        final tmp = await getTemporaryDirectory();
        final outPath = p.join(tmp.path, fileName);
        await File(outPath).writeAsBytes(bytes);

        await SharePlus.instance.share(
          ShareParams(files: [XFile(outPath)], text: 'RescueAuthKit Backup'),
        );

        if (context.mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text(l10n.backupExportShared)));
        }
      } else {
        final loc = await getSaveLocation(suggestedName: fileName);
        if (loc == null) return;

        final xf = XFile.fromData(
          bytes,
          mimeType: 'application/octet-stream',
          name: fileName,
        );
        await xf.saveTo(loc.path);

        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(l10n.backupExportedTo(loc.path))),
          );
        }
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.backupExportFailed(e.toString()))),
        );
      }
    }
  }

  Future<void> _importVault(BuildContext context) async {
    final l10n = AppLocalizations.of(context);

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

      final pw = await _askPassword(context, title: l10n.backupPasswordTitle);
      if (pw == null || pw.isEmpty) return;

      final bytes = Uint8List.fromList(await file.readAsBytes());

      if (!context.mounted) return;

      await context.read<VaultSession>().importVault(
        vaultBytes: bytes,
        password: pw,
      );

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.backupImportedFrom(file.name))),
        );
      }
    } on VaultAuthException {
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(l10n.backupWrongPassword)));
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.backupImportFailed(e.toString()))),
        );
      }
    }
  }
}

class VersionInfoScreen extends StatefulWidget {
  const VersionInfoScreen({super.key});

  @override
  State<VersionInfoScreen> createState() => _VersionInfoScreenState();
}

class _VersionInfoScreenState extends State<VersionInfoScreen> {
  final UpdateChecker _updateChecker = const UpdateChecker();

  late final Future<PackageInfo?> _packageInfoFuture;
  bool _checkingForUpdates = false;
  UpdateCheckResult? _lastUpdateCheck;

  @override
  void initState() {
    super.initState();
    _packageInfoFuture = _loadPackageInfo();
  }

  Future<PackageInfo?> _loadPackageInfo() async {
    try {
      return await PackageInfo.fromPlatform();
    } catch (_) {
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return Scaffold(
      appBar: AppBar(title: Text(l10n.settingsVersionTitle)),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            child: ListTile(
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 12,
              ),
              leading: const Icon(Icons.info_outline),
              title: Text(l10n.settingsVersionTitle),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 4),
                  FutureBuilder<PackageInfo?>(
                    future: _packageInfoFuture,
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return Text(l10n.settingsLoadingVersion);
                      }

                      final packageInfo = snapshot.data;
                      final version = packageInfo == null
                          ? l10n.settingsUnknownVersion
                          : '${packageInfo.version}+${packageInfo.buildNumber}';

                      return Text(l10n.settingsAppVersion(version));
                    },
                  ),
                  const SizedBox(height: 4),
                  Text(l10n.settingsVersionSubtitle),
                ],
              ),
            ),
          ),
          if (_lastUpdateCheck != null) ...[
            const SizedBox(height: 16),
            _buildReleaseCard(context, _lastUpdateCheck!),
          ],
        ],
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
          child: Center(
            widthFactor: 1,
            heightFactor: 1,
            child: FilledButton.icon(
              icon: _checkingForUpdates
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.system_update),
              label: Text(
                _checkingForUpdates
                    ? l10n.settingsCheckingUpdates
                    : l10n.settingsCheckUpdates,
              ),
              onPressed: _checkingForUpdates
                  ? null
                  : () => _checkForUpdates(context),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildReleaseCard(BuildContext context, UpdateCheckResult result) {
    final l10n = AppLocalizations.of(context);
    final releaseUrl = result.releaseUrl;
    final releaseLabel = result.releaseName?.trim().isNotEmpty == true
        ? result.releaseName!
        : result.latestTag;

    return Card(
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 12,
        ),
        leading: Icon(
          result.updateAvailable ? Icons.system_update_alt : Icons.check_circle,
        ),
        title: Text(_updateSummary(l10n, result)),
        subtitle: releaseLabel == null ? null : Text(releaseLabel),
        trailing: releaseUrl == null ? null : const Icon(Icons.open_in_new),
        onTap: releaseUrl == null
            ? null
            : () => _openRelease(context, releaseUrl),
      ),
    );
  }

  String _updateSummary(AppLocalizations l10n, UpdateCheckResult result) {
    switch (result.status) {
      case UpdateCheckStatus.updateAvailable:
        return l10n.settingsUpdateAvailable(result.latestTag ?? '');
      case UpdateCheckStatus.upToDate:
        return l10n.settingsNoUpdate(result.latestTag ?? result.currentVersion);
      case UpdateCheckStatus.noReleaseFound:
        return l10n.settingsNoReleaseFound;
      case UpdateCheckStatus.cannotCompare:
        return l10n.settingsUpdateCompareFailed(result.latestTag ?? '');
    }
  }

  Future<void> _checkForUpdates(BuildContext context) async {
    setState(() => _checkingForUpdates = true);

    try {
      final result = await _updateChecker.check();
      if (!context.mounted) return;

      setState(() => _lastUpdateCheck = result);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(_updateSummary(AppLocalizations.of(context), result)),
          action: result.releaseUrl == null
              ? null
              : SnackBarAction(
                  label: AppLocalizations.of(context).settingsOpenRelease,
                  onPressed: () => _openRelease(context, result.releaseUrl!),
                ),
        ),
      );
    } catch (e) {
      if (!context.mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            AppLocalizations.of(
              context,
            ).settingsUpdateCheckFailed(e.toString()),
          ),
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _checkingForUpdates = false);
      }
    }
  }

  Future<void> _openRelease(BuildContext context, String url) async {
    final ok = await launchUrl(
      Uri.parse(url),
      mode: LaunchMode.externalApplication,
    );
    if (!ok && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            AppLocalizations.of(context).settingsUpdateCheckFailed(url),
          ),
        ),
      );
    }
  }
}
