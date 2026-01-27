import 'package:flutter/material.dart';

import '../../l10n/app_localizations.dart';

Future<String?> showPasteOtpauthDialog(BuildContext context) async {
  final l10n = AppLocalizations.of(context);
  final controller = TextEditingController();

  final result = await showDialog<String?>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: Text(l10n.pasteDialogTitle),
      content: TextField(
        controller: controller,
        minLines: 2,
        maxLines: 5,
        decoration: InputDecoration(
          hintText: l10n.pasteDialogHint,
          border: const OutlineInputBorder(),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(ctx),
          child: Text(l10n.dialogCancel),
        ),
        FilledButton(
          onPressed: () => Navigator.pop(ctx, controller.text),
          child: Text(l10n.dialogContinue),
        ),
      ],
    ),
  );

  controller.dispose();
  return result;
}
