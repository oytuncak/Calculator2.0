import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'app/app.dart';
import 'data/repository/document_repository.dart';
import 'domain/serialization/document_codec.dart';
import 'state/document_controller.dart';
import 'state/settings_controller.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Build the persistence + initial document/settings before the app starts so
  // the providers can be created with real state (no loading flash for M1).
  final prefs = await SharedPreferences.getInstance();
  final repository = SharedPrefsDocumentRepository(DocumentCodec());
  final initialDoc = await DocumentController.bootstrap(repository);

  runApp(
    ProviderScope(
      overrides: [
        documentRepositoryProvider.overrideWithValue(repository),
        documentControllerProvider.overrideWith(
          (ref) => DocumentController(repository, initialDoc),
        ),
        settingsControllerProvider.overrideWith(
          (ref) => SettingsController(prefs),
        ),
      ],
      child: const Calculator2App(),
    ),
  );
}
