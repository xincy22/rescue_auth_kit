import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:otp/otp.dart';
import 'package:provider/provider.dart';

import '../../core/vault/vault_models.dart';
import '../../core/vault/vault_session.dart';

class TotpScreen extends StatefulWidget {
  const TotpScreen({super.key});

  @override
  State<TotpScreen> createState() => _TotpScreenState();
}

class _TotpScreenState extends State<TotpScreen> {
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Algorithm _mapAlgorithm(TotpHashAlgorithm algo) {
    return switch (algo) {
      TotpHashAlgorithm.sha1 => Algorithm.SHA1,
      TotpHashAlgorithm.sha256 => Algorithm.SHA256,
      TotpHashAlgorithm.sha512 => Algorithm.SHA512,
    };
  }

  int _remainingSeconds(int period, int epochSeconds) {
    final passed = epochSeconds % period;
    return period - passed;
  }

  @override
  Widget build(BuildContext context) {
    final session = context.watch<VaultSession>();
    final entries = session.data.totpEntries;

    final now = DateTime.now();
    final epochSeconds = now.millisecondsSinceEpoch ~/ 1000;

    if (entries.isEmpty) {
      return const Center(child: Text('No TOTP entries available.'));
    }

    return ListView.separated(
      padding: const EdgeInsets.all(12),
      itemCount: entries.length,
      separatorBuilder: (_, __) => const SizedBox(height: 8),
      itemBuilder: (context, index) {
        final e = entries[index];

        final remaining = _remainingSeconds(e.period, epochSeconds);
        final progress = remaining / e.period;

        String code;
        try {
          code = OTP.generateTOTPCodeString(
            e.secretBase32,
            now.millisecondsSinceEpoch,
            length: e.digits,
            interval: e.period,
            algorithm: _mapAlgorithm(e.algorithm),
            isGoogle: false,
          );
        } catch (_) {
          code = 'Error';
        }

        return Card(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  e.issuer.isEmpty ? '(No issuer)' : e.issuer,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                Text(
                  e.accountName,
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Text(
                      code,
                      style: Theme.of(context).textTheme.headlineMedium,
                    ),
                    const Spacer(),
                    IconButton(
                      tooltip: 'Copy',
                      onPressed: () async {
                        await Clipboard.setData(ClipboardData(text: code));
                        if (!context.mounted) return;
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('TOTP code copied to clipboard'),
                          ),
                        );
                      },
                      icon: const Icon(Icons.copy),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                LinearProgressIndicator(value: progress),
                const SizedBox(height: 6),
                Text('Expires in $remaining seconds'),
              ],
            ),
          ),
        );
      },
    );
  }
}
