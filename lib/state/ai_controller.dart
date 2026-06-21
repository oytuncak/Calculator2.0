import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../ai/ai_assistant.dart';
import '../ai/claude_ai_assistant.dart';
import '../ai/null_ai_assistant.dart';

/// Stores the user's Anthropic API key locally (bring-your-own-key). The key
/// never leaves the device except in calls the user initiates to Anthropic.
class AiSettingsController extends StateNotifier<String> {
  AiSettingsController(this._prefs) : super(_prefs.getString(_key) ?? '');

  static const _key = 'anthropic_api_key';
  final SharedPreferences _prefs;

  bool get hasKey => state.trim().isNotEmpty;

  void setApiKey(String key) {
    state = key.trim();
    _prefs.setString(_key, state);
  }

  void clear() {
    state = '';
    _prefs.remove(_key);
  }
}

final aiSettingsProvider = StateNotifierProvider<AiSettingsController, String>(
  (ref) => throw UnimplementedError(
    'aiSettingsProvider must be overridden in main()',
  ),
);

/// The active assistant: a real Claude client when a key is set, else a no-op.
final aiAssistantProvider = Provider<AiAssistant>((ref) {
  final key = ref.watch(aiSettingsProvider);
  if (key.trim().isEmpty) return const NullAiAssistant();
  return ClaudeAiAssistant(apiKey: key.trim());
});
