import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/import/otpauth_parser.dart';
import '../../core/vault/vault_models.dart';
import '../../core/vault/vault_session.dart';
import '../../l10n/app_localizations.dart';

class ConfirmImportScreen extends StatefulWidget {
  const ConfirmImportScreen({super.key, required this.otpauthUri});

  final String otpauthUri;

  @override
  State<ConfirmImportScreen> createState() => _ConfirmImportScreenState();
}

class _ConfirmImportScreenState extends State<ConfirmImportScreen> {
  ParsedTotp? _parsed;
  String? _error;

  late final TextEditingController _issuerCtrl;
  late final TextEditingController _accountCtrl;

  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _issuerCtrl = TextEditingController();
    _accountCtrl = TextEditingController();

    try {
      final parsed = parseOtpauthTotpUri(widget.otpauthUri);
      _parsed = parsed;
      _issuerCtrl.text = parsed.issuer;
      _accountCtrl.text = parsed.accountName;
    } catch (e) {
      _error = e.toString();
    }
  }

  @override
  void dispose() {
    _issuerCtrl.dispose();
    _accountCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final l10n = AppLocalizations.of(context);
    final parsed = _parsed;
    if (parsed == null) return;

    setState(() => _saving = true);

    try {
      final adjusted = ParsedTotp(
        issuer: _issuerCtrl.text.trim(),
        accountName: _accountCtrl.text.trim(),
        secretBase32: parsed.secretBase32,
        algorithm: parsed.algorithm,
        digits: parsed.digits,
        period: parsed.period,
      );

      await context.read<VaultSession>().addTotpFromParsed(adjusted);

      if (!mounted) return;
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.importSaved)),
      );
    } catch (e) {
      setState(() => _error = l10n.importSaveFailed(e.toString()));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final parsed = _parsed;

    return Scaffold(
      appBar: AppBar(title: Text(l10n.confirmImportTitle)),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: parsed == null
            ? Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    l10n.confirmImportParseError(_error ?? ''),
                  ),
                  const SizedBox(height: 12),
                  Text(l10n.confirmImportHint),
                ],
              )
            : Column(
                children: [
                  TextField(
                    controller: _issuerCtrl,
                    decoration: InputDecoration(
                      labelText: l10n.issuerLabel,
                      border: const OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _accountCtrl,
                    decoration: InputDecoration(
                      labelText: l10n.accountLabel,
                      border: const OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 12),
                  ListTile(
                    title: Text(l10n.algoDigitsPeriod),
                    subtitle: Text(
                      '${parsed.algorithm.otpauthName} / ${parsed.digits} / ${parsed.period}s',
                    ),
                  ),
                  if (_error != null)
                    Text(
                      _error!,
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.error,
                      ),
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
                          : Text(l10n.saveToVault),
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}
