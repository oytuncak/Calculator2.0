import 'ai_assistant.dart';
import 'ai_commands.dart';

/// Default no-op binding used in v1. Every method reports that AI is not yet
/// configured, so the rest of the app can depend on [AiAssistant] today and a
/// real implementation can drop in later with zero call-site changes.
class NullAiAssistant implements AiAssistant {
  const NullAiAssistant();

  static const _unavailable = 'AI is not configured yet';

  @override
  Future<String> naturalLanguageToExpression(String input) async =>
      throw UnsupportedError(_unavailable);

  @override
  Future<List<ExplainStep>> explain(String rawText) async =>
      const <ExplainStep>[];

  @override
  Future<UnitConversion> convertUnits(String input) async =>
      throw UnsupportedError(_unavailable);

  @override
  Stream<DocumentCommand> drive(String prompt) =>
      const Stream<DocumentCommand>.empty();
}
