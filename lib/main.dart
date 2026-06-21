import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'app/app.dart';
import 'data/repository/workspace_repository.dart';
import 'domain/serialization/workspace_codec.dart';
import 'state/ai_controller.dart';
import 'state/document_controller.dart';
import 'state/settings_controller.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Build persistence + initial workspace/settings before the app starts so
  // the providers can be created with real state (no loading flash).
  final prefs = await SharedPreferences.getInstance();
  final repository = SharedPrefsWorkspaceRepository(WorkspaceCodec());
  final initialDoc = await DocumentController.bootstrap(repository);

  runApp(
    ProviderScope(
      overrides: [
        workspaceRepositoryProvider.overrideWithValue(repository),
        documentControllerProvider.overrideWith(
          (ref) => DocumentController(repository, initialDoc),
        ),
        settingsControllerProvider.overrideWith(
          (ref) => SettingsController(prefs),
        ),
        aiSettingsProvider.overrideWith((ref) => AiSettingsController(prefs)),
      ],
      child: const Calculator2App(),
    ),
  );
}
