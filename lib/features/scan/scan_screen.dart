import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

class ScanScreen extends StatefulWidget {
  const ScanScreen({super.key});

  @override
  State<ScanScreen> createState() => _ScanScreenState();
}

class _ScanScreenState extends State<ScanScreen> {
  final MobileScannerController _controller = MobileScannerController();
  bool _handled = false;

  @override
  Future<void> dispose() async {
    await _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Scan QR Code')),
      body: MobileScanner(
        controller: _controller,
        onDetect: (result) {
          if (_handled) return;
          final raw = result.barcodes.isNotEmpty
              ? result.barcodes.first.rawValue
              : null;
          if (raw == null || raw.trim().isEmpty) return;

          _handled = true;
          Navigator.of(context).pop(raw);
        },
      ),
    );
  }
}
