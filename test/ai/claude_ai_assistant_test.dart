import 'dart:convert';

import 'package:calculator2/ai/claude_ai_assistant.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

void main() {
  test('parses the model response into an expression', () async {
    late http.Request captured;
    final client = MockClient((request) async {
      captured = request;
      return http.Response(
        jsonEncode({
          'content': [
            {'type': 'text', 'text': '(240 + 240 * 18%) / 3'},
          ],
        }),
        200,
        headers: {'content-type': 'application/json'},
      );
    });

    final ai = ClaudeAiAssistant(apiKey: 'sk-test', client: client);
    final expr = await ai.naturalLanguageToExpression(
      '18% tip on 240 split 3 ways',
    );

    expect(expr, '(240 + 240 * 18%) / 3');
    // Sends the API key and the browser-access header.
    expect(captured.headers['x-api-key'], 'sk-test');
    expect(
      captured.headers['anthropic-dangerous-direct-browser-access'],
      'true',
    );
    final body = jsonDecode(captured.body) as Map<String, dynamic>;
    expect(body['model'], isNotEmpty);
    expect((body['messages'] as List).first['content'], contains('tip'));
  });

  test('strips accidental code fences', () async {
    final client = MockClient((request) async {
      return http.Response(
        jsonEncode({
          'content': [
            {'type': 'text', 'text': '```\nsqrt(144) + 10\n```'},
          ],
        }),
        200,
      );
    });
    final ai = ClaudeAiAssistant(apiKey: 'k', client: client);
    expect(await ai.naturalLanguageToExpression('x'), 'sqrt(144) + 10');
  });

  test('surfaces API errors as AiException', () async {
    final client = MockClient((request) async {
      return http.Response(
        jsonEncode({
          'error': {'message': 'invalid x-api-key'},
        }),
        401,
      );
    });
    final ai = ClaudeAiAssistant(apiKey: 'bad', client: client);
    expect(
      () => ai.naturalLanguageToExpression('x'),
      throwsA(isA<AiException>()),
    );
  });
}
