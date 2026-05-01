import 'dart:convert';
import 'dart:io';

import 'package:file_selector/file_selector.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';

import '../../core/vault/vault_models.dart';
import '../../core/vault/vault_session.dart';
import '../../l10n/app_localizations.dart';

Future<void> showAddDeveloperEntrySheet(BuildContext context) async {
  final l10n = AppLocalizations.of(context);
  final type = await showModalBottomSheet<DeveloperEntryType>(
    context: context,
    builder: (ctx) => SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(
                l10n.developerAddTitle,
                style: Theme.of(ctx).textTheme.titleMedium,
              ),
            ),
          ),
          for (final item in DeveloperEntryType.values)
            ListTile(
              leading: Icon(_developerTypeIcon(item)),
              title: Text(_developerTypeLabel(l10n, item)),
              onTap: () => Navigator.pop(ctx, item),
            ),
        ],
      ),
    ),
  );

  if (!context.mounted || type == null) return;

  await Navigator.of(context).push(
    MaterialPageRoute(builder: (_) => DeveloperEntryFormScreen(type: type)),
  );
}

class DeveloperScreen extends StatelessWidget {
  const DeveloperScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final entries = context.watch<VaultSession>().data.developerEntries;

    if (entries.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Text(
            l10n.developerEmpty,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyLarge,
          ),
        ),
      );
    }

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        for (final type in DeveloperEntryType.values) ...[
          if (entries.any((entry) => entry.type == type)) ...[
            Padding(
              padding: const EdgeInsets.fromLTRB(4, 12, 4, 8),
              child: Text(
                _developerTypeLabel(l10n, type),
                style: Theme.of(context).textTheme.titleMedium,
              ),
            ),
            for (final entry in entries.where((entry) => entry.type == type))
              Card(
                child: ListTile(
                  leading: Icon(_developerTypeIcon(entry.type)),
                  title: Text(entry.title),
                  subtitle: entry.notes.isEmpty ? null : Text(entry.notes),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) =>
                          DeveloperEntryDetailScreen(entryId: entry.id),
                    ),
                  ),
                ),
              ),
          ],
        ],
      ],
    );
  }
}

class DeveloperEntryFormScreen extends StatefulWidget {
  const DeveloperEntryFormScreen({super.key, required this.type, this.entry});

  final DeveloperEntryType type;
  final DeveloperEntry? entry;

  @override
  State<DeveloperEntryFormScreen> createState() =>
      _DeveloperEntryFormScreenState();
}

class _DeveloperEntryFormScreenState extends State<DeveloperEntryFormScreen> {
  final _titleCtrl = TextEditingController();
  final _notesCtrl = TextEditingController();
  final _projectNameCtrl = TextEditingController();
  final _packageNameCtrl = TextEditingController();
  final _storePasswordCtrl = TextEditingController();
  final _keyAliasCtrl = TextEditingController();
  final _keyPasswordCtrl = TextEditingController();
  final _serviceNameCtrl = TextEditingController();
  final _accountNameCtrl = TextEditingController();
  final _apiKeyCtrl = TextEditingController();
  final _apiSecretCtrl = TextEditingController();
  final _keyNameCtrl = TextEditingController();
  final _publicKeyCtrl = TextEditingController();
  final _privateKeyCtrl = TextEditingController();
  final _passphraseCtrl = TextEditingController();
  final _variablesCtrl = TextEditingController();
  final _fieldsCtrl = TextEditingController();

  String? _keystoreFileName;
  String? _keystoreBytesBase64;

  @override
  void initState() {
    super.initState();
    final entry = widget.entry;
    if (entry == null) return;

    final payload = entry.payload;
    _titleCtrl.text = entry.title;
    _notesCtrl.text = entry.notes;
    _projectNameCtrl.text = _payloadString(payload, 'projectName');
    _packageNameCtrl.text = _payloadString(payload, 'packageName');
    _storePasswordCtrl.text = _payloadString(payload, 'storePassword');
    _keyAliasCtrl.text = _payloadString(payload, 'keyAlias');
    _keyPasswordCtrl.text = _payloadString(payload, 'keyPassword');
    _keystoreFileName = _payloadString(payload, 'keystoreFileName');
    _keystoreBytesBase64 = _payloadString(payload, 'keystoreBytesBase64');
    _serviceNameCtrl.text = _payloadString(payload, 'serviceName');
    _accountNameCtrl.text = _payloadString(payload, 'accountName');
    _apiKeyCtrl.text = _payloadString(payload, 'apiKey');
    _apiSecretCtrl.text = _payloadString(payload, 'apiSecret');
    _keyNameCtrl.text = _payloadString(payload, 'keyName');
    _publicKeyCtrl.text = _payloadString(payload, 'publicKey');
    _privateKeyCtrl.text = _payloadString(payload, 'privateKey');
    _passphraseCtrl.text = _payloadString(payload, 'passphrase');
    _variablesCtrl.text = _pairsToLines(payload['variables']);
    _fieldsCtrl.text = _pairsToLines(payload['fields']);
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    _notesCtrl.dispose();
    _projectNameCtrl.dispose();
    _packageNameCtrl.dispose();
    _storePasswordCtrl.dispose();
    _keyAliasCtrl.dispose();
    _keyPasswordCtrl.dispose();
    _serviceNameCtrl.dispose();
    _accountNameCtrl.dispose();
    _apiKeyCtrl.dispose();
    _apiSecretCtrl.dispose();
    _keyNameCtrl.dispose();
    _publicKeyCtrl.dispose();
    _privateKeyCtrl.dispose();
    _passphraseCtrl.dispose();
    _variablesCtrl.dispose();
    _fieldsCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(_developerTypeLabel(l10n, widget.type)),
        actions: [
          TextButton(onPressed: _save, child: Text(l10n.developerSave)),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _textField(_titleCtrl, l10n.developerTitleLabel),
          const SizedBox(height: 12),
          _textField(_notesCtrl, l10n.developerNotesLabel, maxLines: 3),
          const SizedBox(height: 16),
          ..._buildTypeFields(l10n),
        ],
      ),
    );
  }

  List<Widget> _buildTypeFields(AppLocalizations l10n) {
    return switch (widget.type) {
      DeveloperEntryType.androidSigningKey => [
        _textField(_projectNameCtrl, l10n.developerProjectNameLabel),
        const SizedBox(height: 12),
        _textField(_packageNameCtrl, l10n.developerPackageNameLabel),
        const SizedBox(height: 12),
        OutlinedButton.icon(
          onPressed: _pickKeystoreFile,
          icon: const Icon(Icons.attach_file),
          label: Text(_keystoreFileName ?? l10n.developerChooseFile),
        ),
        const SizedBox(height: 12),
        _textField(_storePasswordCtrl, 'storePassword', obscure: true),
        const SizedBox(height: 12),
        _textField(_keyAliasCtrl, 'keyAlias'),
        const SizedBox(height: 12),
        _textField(_keyPasswordCtrl, 'keyPassword', obscure: true),
      ],
      DeveloperEntryType.apiCredential => [
        _textField(_serviceNameCtrl, l10n.developerServiceNameLabel),
        const SizedBox(height: 12),
        _textField(_accountNameCtrl, l10n.accountLabel),
        const SizedBox(height: 12),
        _textField(_apiKeyCtrl, l10n.developerApiKeyLabel, obscure: true),
        const SizedBox(height: 12),
        _textField(_apiSecretCtrl, l10n.developerApiSecretLabel, obscure: true),
      ],
      DeveloperEntryType.sshKey => [
        _textField(_keyNameCtrl, l10n.developerKeyNameLabel),
        const SizedBox(height: 12),
        _textField(_publicKeyCtrl, l10n.developerPublicKeyLabel, maxLines: 4),
        const SizedBox(height: 12),
        _textField(
          _privateKeyCtrl,
          l10n.developerPrivateKeyLabel,
          maxLines: 8,
          obscure: true,
        ),
        const SizedBox(height: 12),
        _textField(
          _passphraseCtrl,
          l10n.developerPassphraseLabel,
          obscure: true,
        ),
      ],
      DeveloperEntryType.envVarSet => [
        _textField(_projectNameCtrl, l10n.developerProjectNameLabel),
        const SizedBox(height: 12),
        _textField(
          _variablesCtrl,
          l10n.developerEnvVariablesLabel,
          hint: 'API_KEY=value\nDATABASE_URL=value',
          maxLines: 8,
        ),
      ],
      DeveloperEntryType.genericSecret => [
        _textField(
          _fieldsCtrl,
          l10n.developerGenericFieldsLabel,
          hint: 'label=value\nanother=value',
          maxLines: 8,
        ),
      ],
    };
  }

  Widget _textField(
    TextEditingController controller,
    String label, {
    String? hint,
    int maxLines = 1,
    bool obscure = false,
  }) {
    return TextField(
      controller: controller,
      obscureText: obscure,
      maxLines: obscure ? 1 : maxLines,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        border: const OutlineInputBorder(),
      ),
    );
  }

  Future<void> _pickKeystoreFile() async {
    final file = await openFile(
      acceptedTypeGroups: const [
        XTypeGroup(
          label: 'Android Keystore',
          extensions: <String>['jks', 'keystore'],
        ),
      ],
    );
    if (file == null) return;

    final bytes = await file.readAsBytes();
    setState(() {
      _keystoreFileName = file.name;
      _keystoreBytesBase64 = base64Encode(bytes);
    });
  }

  Future<void> _save() async {
    final l10n = AppLocalizations.of(context);
    final payload = _payloadForType();
    if (payload == null) return;

    final title = _titleCtrl.text.trim().isEmpty
        ? _fallbackTitle(l10n)
        : _titleCtrl.text.trim();

    try {
      final session = context.read<VaultSession>();
      if (widget.entry == null) {
        await session.addDeveloperEntry(
          type: widget.type,
          title: title,
          notes: _notesCtrl.text,
          payload: payload,
        );
      } else {
        await session.updateDeveloperEntry(
          id: widget.entry!.id,
          title: title,
          notes: _notesCtrl.text,
          payload: payload,
        );
      }

      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(l10n.developerSaved)));
      Navigator.pop(context);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.developerSaveFailed(e.toString()))),
      );
    }
  }

  Map<String, dynamic>? _payloadForType() {
    final l10n = AppLocalizations.of(context);
    return switch (widget.type) {
      DeveloperEntryType.androidSigningKey => _androidSigningPayload(l10n),
      DeveloperEntryType.apiCredential => <String, dynamic>{
        'serviceName': _serviceNameCtrl.text.trim(),
        'accountName': _accountNameCtrl.text.trim(),
        'apiKey': _apiKeyCtrl.text,
        'apiSecret': _apiSecretCtrl.text,
      },
      DeveloperEntryType.sshKey => <String, dynamic>{
        'keyName': _keyNameCtrl.text.trim(),
        'publicKey': _publicKeyCtrl.text,
        'privateKey': _privateKeyCtrl.text,
        'passphrase': _passphraseCtrl.text,
      },
      DeveloperEntryType.envVarSet => <String, dynamic>{
        'projectName': _projectNameCtrl.text.trim(),
        'variables': _parsePairs(_variablesCtrl.text, 'name', 'value'),
      },
      DeveloperEntryType.genericSecret => <String, dynamic>{
        'fields': _parsePairs(_fieldsCtrl.text, 'label', 'value'),
      },
    };
  }

  Map<String, dynamic>? _androidSigningPayload(AppLocalizations l10n) {
    if ((_keystoreBytesBase64 ?? '').isEmpty ||
        (_keystoreFileName ?? '').isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(l10n.developerFileRequired)));
      return null;
    }

    return <String, dynamic>{
      'projectName': _projectNameCtrl.text.trim(),
      'packageName': _packageNameCtrl.text.trim(),
      'keystoreFileName': _keystoreFileName,
      'keystoreBytesBase64': _keystoreBytesBase64,
      'storePassword': _storePasswordCtrl.text,
      'keyAlias': _keyAliasCtrl.text.trim(),
      'keyPassword': _keyPasswordCtrl.text,
    };
  }

  String _fallbackTitle(AppLocalizations l10n) {
    return switch (widget.type) {
      DeveloperEntryType.androidSigningKey =>
        _projectNameCtrl.text.trim().isNotEmpty
            ? _projectNameCtrl.text.trim()
            : _developerTypeLabel(l10n, widget.type),
      DeveloperEntryType.apiCredential =>
        _serviceNameCtrl.text.trim().isNotEmpty
            ? _serviceNameCtrl.text.trim()
            : _developerTypeLabel(l10n, widget.type),
      DeveloperEntryType.sshKey =>
        _keyNameCtrl.text.trim().isNotEmpty
            ? _keyNameCtrl.text.trim()
            : _developerTypeLabel(l10n, widget.type),
      DeveloperEntryType.envVarSet =>
        _projectNameCtrl.text.trim().isNotEmpty
            ? _projectNameCtrl.text.trim()
            : _developerTypeLabel(l10n, widget.type),
      DeveloperEntryType.genericSecret => _developerTypeLabel(
        l10n,
        widget.type,
      ),
    };
  }
}

class DeveloperEntryDetailScreen extends StatelessWidget {
  const DeveloperEntryDetailScreen({super.key, required this.entryId});

  final String entryId;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final entries = context.watch<VaultSession>().data.developerEntries;
    final matches = entries.where((entry) => entry.id == entryId);

    if (matches.isEmpty) {
      return Scaffold(
        appBar: AppBar(title: Text(l10n.tabDeveloper)),
        body: Center(child: Text(l10n.developerEntryMissing)),
      );
    }

    final entry = matches.single;

    return Scaffold(
      appBar: AppBar(
        title: Text(entry.title),
        actions: [
          IconButton(
            tooltip: l10n.developerEdit,
            icon: const Icon(Icons.edit),
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) =>
                    DeveloperEntryFormScreen(type: entry.type, entry: entry),
              ),
            ),
          ),
          IconButton(
            tooltip: l10n.deleteButton,
            icon: const Icon(Icons.delete_outline),
            onPressed: () => _confirmDelete(context, entry),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          if (entry.notes.isNotEmpty) ...[
            Text(entry.notes),
            const SizedBox(height: 16),
          ],
          ..._detailRows(context, entry),
        ],
      ),
    );
  }

  List<Widget> _detailRows(BuildContext context, DeveloperEntry entry) {
    final l10n = AppLocalizations.of(context);
    final payload = entry.payload;

    return switch (entry.type) {
      DeveloperEntryType.androidSigningKey => [
        _ValueTile(
          label: l10n.developerProjectNameLabel,
          value: _payloadString(payload, 'projectName'),
        ),
        _ValueTile(
          label: l10n.developerPackageNameLabel,
          value: _payloadString(payload, 'packageName'),
        ),
        _ValueTile(
          label: l10n.developerKeystoreFileLabel,
          value: _payloadString(payload, 'keystoreFileName'),
        ),
        _SecretValueTile(
          label: 'storePassword',
          value: _payloadString(payload, 'storePassword'),
        ),
        _ValueTile(
          label: 'keyAlias',
          value: _payloadString(payload, 'keyAlias'),
        ),
        _SecretValueTile(
          label: 'keyPassword',
          value: _payloadString(payload, 'keyPassword'),
        ),
        const SizedBox(height: 12),
        FilledButton.icon(
          onPressed: () => _exportKeystore(context, entry),
          icon: const Icon(Icons.save_alt),
          label: Text(l10n.developerExportKeystore),
        ),
        const SizedBox(height: 8),
        OutlinedButton.icon(
          onPressed: () => _copyKeyProperties(context, entry),
          icon: const Icon(Icons.copy),
          label: Text(l10n.developerCopyKeyProperties),
        ),
      ],
      DeveloperEntryType.apiCredential => [
        _ValueTile(
          label: l10n.developerServiceNameLabel,
          value: _payloadString(payload, 'serviceName'),
        ),
        _ValueTile(
          label: l10n.accountLabel,
          value: _payloadString(payload, 'accountName'),
        ),
        _SecretValueTile(
          label: l10n.developerApiKeyLabel,
          value: _payloadString(payload, 'apiKey'),
        ),
        _SecretValueTile(
          label: l10n.developerApiSecretLabel,
          value: _payloadString(payload, 'apiSecret'),
        ),
      ],
      DeveloperEntryType.sshKey => [
        _ValueTile(
          label: l10n.developerKeyNameLabel,
          value: _payloadString(payload, 'keyName'),
        ),
        _ValueTile(
          label: l10n.developerPublicKeyLabel,
          value: _payloadString(payload, 'publicKey'),
        ),
        _SecretValueTile(
          label: l10n.developerPrivateKeyLabel,
          value: _payloadString(payload, 'privateKey'),
        ),
        _SecretValueTile(
          label: l10n.developerPassphraseLabel,
          value: _payloadString(payload, 'passphrase'),
        ),
      ],
      DeveloperEntryType.envVarSet => [
        _ValueTile(
          label: l10n.developerProjectNameLabel,
          value: _payloadString(payload, 'projectName'),
        ),
        for (final pair in _payloadPairs(payload['variables']))
          _SecretValueTile(label: pair.$1, value: pair.$2),
      ],
      DeveloperEntryType.genericSecret => [
        for (final pair in _payloadPairs(payload['fields']))
          _SecretValueTile(label: pair.$1, value: pair.$2),
      ],
    };
  }

  Future<void> _confirmDelete(
    BuildContext context,
    DeveloperEntry entry,
  ) async {
    final l10n = AppLocalizations.of(context);
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.developerDeleteTitle),
        content: Text(entry.title),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(l10n.dialogCancel),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(l10n.deleteButton),
          ),
        ],
      ),
    );
    if (ok != true || !context.mounted) return;

    await context.read<VaultSession>().removeDeveloperEntry(entry.id);
    if (context.mounted) Navigator.pop(context);
  }

  Future<void> _copyKeyProperties(
    BuildContext context,
    DeveloperEntry entry,
  ) async {
    final l10n = AppLocalizations.of(context);
    final payload = entry.payload;
    final fileName = _payloadString(payload, 'keystoreFileName');
    final content = [
      'storePassword=${_payloadString(payload, 'storePassword')}',
      'keyPassword=${_payloadString(payload, 'keyPassword')}',
      'keyAlias=${_payloadString(payload, 'keyAlias')}',
      'storeFile=app/$fileName',
      '',
    ].join('\n');

    await Clipboard.setData(ClipboardData(text: content));
    if (context.mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(l10n.copied)));
    }
  }

  Future<void> _exportKeystore(
    BuildContext context,
    DeveloperEntry entry,
  ) async {
    final l10n = AppLocalizations.of(context);
    final payload = entry.payload;
    final fileName = _payloadString(payload, 'keystoreFileName').isEmpty
        ? 'upload-keystore.jks'
        : _payloadString(payload, 'keystoreFileName');
    final bytes = base64Decode(_payloadString(payload, 'keystoreBytesBase64'));

    final isAndroid =
        !kIsWeb && defaultTargetPlatform == TargetPlatform.android;

    if (isAndroid) {
      final tmp = await getTemporaryDirectory();
      final outPath = p.join(tmp.path, fileName);
      await File(outPath).writeAsBytes(bytes);
      await SharePlus.instance.share(
        ShareParams(files: [XFile(outPath)], text: entry.title),
      );
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(l10n.developerFileShared)));
      }
      return;
    }

    final loc = await getSaveLocation(suggestedName: fileName);
    if (loc == null) return;
    await XFile.fromData(bytes, name: fileName).saveTo(loc.path);

    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.developerFileExported(loc.path))),
      );
    }
  }
}

class _ValueTile extends StatelessWidget {
  const _ValueTile({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Card(
      child: ListTile(
        title: Text(label),
        subtitle: SelectableText(value.isEmpty ? '-' : value),
        trailing: IconButton(
          tooltip: l10n.copied,
          icon: const Icon(Icons.copy),
          onPressed: value.isEmpty
              ? null
              : () async {
                  await Clipboard.setData(ClipboardData(text: value));
                  if (context.mounted) {
                    ScaffoldMessenger.of(
                      context,
                    ).showSnackBar(SnackBar(content: Text(l10n.copied)));
                  }
                },
        ),
      ),
    );
  }
}

class _SecretValueTile extends StatefulWidget {
  const _SecretValueTile({required this.label, required this.value});

  final String label;
  final String value;

  @override
  State<_SecretValueTile> createState() => _SecretValueTileState();
}

class _SecretValueTileState extends State<_SecretValueTile> {
  bool _revealed = false;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final shown = _revealed ? widget.value : _mask(widget.value);

    return Card(
      child: ListTile(
        title: Text(widget.label),
        subtitle: SelectableText(widget.value.isEmpty ? '-' : shown),
        trailing: Wrap(
          spacing: 4,
          children: [
            IconButton(
              tooltip: _revealed
                  ? l10n.developerHideSecret
                  : l10n.developerShowSecret,
              icon: Icon(_revealed ? Icons.visibility_off : Icons.visibility),
              onPressed: widget.value.isEmpty
                  ? null
                  : () => setState(() => _revealed = !_revealed),
            ),
            IconButton(
              tooltip: l10n.copied,
              icon: const Icon(Icons.copy),
              onPressed: widget.value.isEmpty
                  ? null
                  : () async {
                      await Clipboard.setData(
                        ClipboardData(text: widget.value),
                      );
                      if (context.mounted) {
                        ScaffoldMessenger.of(
                          context,
                        ).showSnackBar(SnackBar(content: Text(l10n.copied)));
                      }
                    },
            ),
          ],
        ),
      ),
    );
  }
}

String _developerTypeLabel(AppLocalizations l10n, DeveloperEntryType type) {
  return switch (type) {
    DeveloperEntryType.androidSigningKey => l10n.developerAndroidSigningKey,
    DeveloperEntryType.apiCredential => l10n.developerApiCredential,
    DeveloperEntryType.sshKey => l10n.developerSshKey,
    DeveloperEntryType.envVarSet => l10n.developerEnvVarSet,
    DeveloperEntryType.genericSecret => l10n.developerGenericSecret,
  };
}

IconData _developerTypeIcon(DeveloperEntryType type) {
  return switch (type) {
    DeveloperEntryType.androidSigningKey => Icons.android,
    DeveloperEntryType.apiCredential => Icons.api,
    DeveloperEntryType.sshKey => Icons.terminal,
    DeveloperEntryType.envVarSet => Icons.tune,
    DeveloperEntryType.genericSecret => Icons.vpn_key,
  };
}

String _payloadString(Map<String, dynamic> payload, String key) {
  return payload[key]?.toString() ?? '';
}

List<Map<String, String>> _parsePairs(
  String raw,
  String labelKey,
  String valueKey,
) {
  return raw
      .split('\n')
      .map((line) => line.trim())
      .where((line) => line.isNotEmpty)
      .map((line) {
        final separator = line.indexOf('=');
        if (separator < 0) {
          return <String, String>{labelKey: line, valueKey: ''};
        }
        return <String, String>{
          labelKey: line.substring(0, separator).trim(),
          valueKey: line.substring(separator + 1).trim(),
        };
      })
      .where((pair) => pair[labelKey]!.isNotEmpty)
      .toList(growable: false);
}

String _pairsToLines(Object? raw) {
  return _payloadPairs(raw).map((pair) => '${pair.$1}=${pair.$2}').join('\n');
}

List<(String, String)> _payloadPairs(Object? raw) {
  if (raw is! List) return const [];
  return raw
      .whereType<Map>()
      .map((item) {
        final label = (item['name'] ?? item['label'] ?? '').toString();
        final value = (item['value'] ?? '').toString();
        return (label, value);
      })
      .where((pair) => pair.$1.isNotEmpty)
      .toList(growable: false);
}

String _mask(String value) {
  if (value.isEmpty) return '';
  return '•' * value.length.clamp(6, 16);
}
