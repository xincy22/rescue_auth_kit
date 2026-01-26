import 'package:flutter/material.dart';

import 'app.dart';
import 'core/vault/vault_repository.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final repo = await VaultRepository.create();
  runApp(RescueAuthKitApp(vaultRepository: repo));
}
