import 'package:flutter/material.dart';

Future<String?> showPasteOtpauthDialog(BuildContext context) async {
  final controller = TextEditingController();

  final result = await showDialog<String?>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: const Text('Paste otpauth URI'),
      content: TextField(
        controller: controller,
        minLines: 2,
        maxLines: 5,
        decoration: const InputDecoration(
          hintText: 'otpauth://totp/Issuer:Account?secret=...',
          border: OutlineInputBorder(),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(ctx),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: () => Navigator.pop(ctx, controller.text),
          child: const Text('OK'),
        ),
      ],
    ),
  );

  controller.dispose();
  return result;
}
