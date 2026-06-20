import 'ai_commands.dart';

/// One step in an explanation of how a result was reached.
class ExplainStep {
  const ExplainStep(this.description, this.value);
  final String description;
  final String value;
}

/// Result of a smart unit / currency conversion.
class UnitConversion {
  const UnitConversion({
    required this.value,
    required this.fromUnit,
    required this.toUnit,
    required this.expression,
  });
  final double value;
  final String fromUnit;
  final String toUnit;

  /// Canonical engine text that can be dropped onto the canvas.
  final String expression;
}

/// The AI seam. The app depends on this interface, never a concrete model, so
/// AI can be swapped in/out (or routed through a Claude/MCP server) without
/// touching the canvas or engine.
///
/// v1 ships [NullAiAssistant]; the roadmap implements these against a backend.
abstract interface class AiAssistant {
  /// Turns natural language ("18% tip on 240 split 3 ways") into canonical
  /// engine text that the existing parser understands.
  Future<String> naturalLanguageToExpression(String input);

  /// Explains how an element's result was computed, step by step.
  Future<List<ExplainStep>> explain(String rawText);

  /// Smart unit & currency conversion, including live exchange rates.
  Future<UnitConversion> convertUnits(String input);

  /// "Talk to the calculator": streams document commands that drive the
  /// canvas. Backed later by a Claude/MCP server emitting tool calls that map
  /// 1:1 to [DocumentCommand]s.
  Stream<DocumentCommand> drive(String prompt);
}
