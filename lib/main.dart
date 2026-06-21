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

  try {
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
  } catch (e, st) {
    // Surface a startup failure instead of leaving a blank screen.
    runApp(_StartupErrorApp('$e\n\n$st'));
  }
}

class _StartupErrorApp extends StatelessWidget {
  const _StartupErrorApp(this.message);
  final String message;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.error_outline, color: Colors.red, size: 40),
                  const SizedBox(height: 12),
                  const Text(
                    'Calculator 2.0 failed to start',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                  const SizedBox(height: 8),
                  Text(message, style: const TextStyle(fontSize: 12)),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
