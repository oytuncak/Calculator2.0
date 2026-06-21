import 'dart:convert';

import 'package:http/http.dart' as http;

import 'ai_assistant.dart';
import 'ai_commands.dart';

/// Calls the Anthropic Messages API directly with a user-supplied API key
/// (bring-your-own-key). On web, the dangerous-direct-browser-access header
/// lets the request run from the browser.
///
/// v1 implements [naturalLanguageToExpression]; the other methods are reserved
/// for later milestones.
class ClaudeAiAssistant implements AiAssistant {
  ClaudeAiAssistant({
    required this.apiKey,
    this.model = 'claude-haiku-4-5-20251001',
    http.Client? client,
  }) : _client = client ?? http.Client();

  final String apiKey;
  final String model;
  final http.Client _client;

  static final Uri _endpoint = Uri.parse(
    'https://api.anthropic.com/v1/messages',
  );

  static const _systemPrompt = '''
You convert a natural-language calculation request into a single expression for a
calculator engine. Reply with ONLY the expression — no prose, no explanation, no
"=", no surrounding code fences.

Supported syntax:
- operators: + - * / % ^ and parentheses ( )
- percent is contextual: "100 + 20%" means 120, "100 - 10%" means 90
- functions: sin cos tan asin acos atan sinh cosh tanh exp abs sign round floor
  ceil rad deg sqrt cbrt ln log log10 pow root mod hypot min max avg sum
- constants: pi e tau
- function arguments are separated by commas, e.g. max(3, 7, 5)

Examples:
- "18% tip on 240 split 3 ways" -> (240 + 240 * 18%) / 3
- "square root of 144 plus 10" -> sqrt(144) + 10
- "15 percent of 80" -> 80 * 15%
- "2 to the power of 10" -> 2 ^ 10
''';

  @override
  Future<String> naturalLanguageToExpression(String input) async {
    final response = await _client.post(
      _endpoint,
      headers: {
        'content-type': 'application/json',
        'x-api-key': apiKey,
        'anthropic-version': '2023-06-01',
        // Allow the call to run from a browser (Flutter web).
        'anthropic-dangerous-direct-browser-access': 'true',
      },
      body: jsonEncode({
        'model': model,
        'max_tokens': 200,
        'system': _systemPrompt,
        'messages': [
          {'role': 'user', 'content': input},
        ],
      }),
    );

    if (response.statusCode != 200) {
      throw AiException(_describeError(response));
    }

    final json = jsonDecode(response.body) as Map<String, dynamic>;
    final content = (json['content'] as List?) ?? const [];
    final text = content
        .whereType<Map<String, dynamic>>()
        .where((b) => b['type'] == 'text')
        .map((b) => b['text'] as String? ?? '')
        .join()
        .trim();
    if (text.isEmpty) {
      throw const AiException('The AI returned an empty response.');
    }
    return _stripFences(text);
  }

  /// Removes accidental code fences / backticks the model may add.
  String _stripFences(String s) {
    var out = s.trim();
    if (out.startsWith('```')) {
      out = out.replaceAll(RegExp(r'^```[a-zA-Z]*\n?'), '');
      out = out.replaceAll(RegExp(r'\n?```$'), '');
    }
    return out.replaceAll('`', '').trim();
  }

  String _describeError(http.Response response) {
    try {
      final json = jsonDecode(response.body) as Map<String, dynamic>;
      final message = (json['error'] as Map?)?['message'];
      if (message is String) {
        return 'AI error (${response.statusCode}): $message';
      }
    } catch (_) {}
    return 'AI request failed (HTTP ${response.statusCode}).';
  }

  @override
  Future<List<ExplainStep>> explain(String rawText) async =>
      throw const AiException('Explain is not available yet.');

  @override
  Future<UnitConversion> convertUnits(String input) async =>
      throw const AiException('Unit conversion is not available yet.');

  @override
  Stream<DocumentCommand> drive(String prompt) =>
      const Stream<DocumentCommand>.empty();
}

/// User-facing AI failure (shown in a snackbar).
class AiException implements Exception {
  const AiException(this.message);
  final String message;
  @override
  String toString() => message;
}
