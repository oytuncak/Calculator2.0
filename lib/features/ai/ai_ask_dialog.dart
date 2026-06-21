import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../ai/ai_commands.dart';
import '../../domain/model/element.dart';
import '../../state/ai_controller.dart';
import '../../state/document_controller.dart';

/// Natural-language input: the user describes a calculation in plain English and
/// the AI turns it into a live equation on the canvas. Uses the user's own
/// Anthropic API key (bring-your-own-key).
class AiAskDialog extends ConsumerStatefulWidget {
  const AiAskDialog({super.key});

  static Future<void> show(BuildContext context) =>
      showDialog(context: context, builder: (_) => const AiAskDialog());

  @override
  ConsumerState<AiAskDialog> createState() => _AiAskDialogState();
}

class _AiAskDialogState extends ConsumerState<AiAskDialog> {
  late final TextEditingController _key = TextEditingController(
    text: ref.read(aiSettingsProvider),
  );
  final _prompt = TextEditingController();
  bool _loading = false;
  String? _error;
  bool _showKey = false;

  @override
  void dispose() {
    _key.dispose();
    _prompt.dispose();
    super.dispose();
  }

  Future<void> _ask() async {
    final prompt = _prompt.text.trim();
    final key = _key.text.trim();
    if (key.isEmpty) {
      setState(() => _error = 'Enter your Anthropic API key first.');
      return;
    }
    if (prompt.isEmpty) {
      setState(() => _error = 'Describe a calculation.');
      return;
    }

    // Persist the key so the assistant provider rebuilds with it.
    ref.read(aiSettingsProvider.notifier).setApiKey(key);

    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final assistant = ref.read(aiAssistantProvider);
      final expression = await assistant.naturalLanguageToExpression(prompt);
      final controller = ref.read(documentControllerProvider.notifier);

      // Place the new equation in a readable column on the current canvas.
      final count = controller.canvas.elements
          .whereType<EquationElement>()
          .length;
      controller.apply(
        AddEquation(x: 80, y: 90 + count * 74.0, rawText: expression),
      );

      if (mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Added:  $expression')));
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _loading = false;
          _error = e.toString();
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final hasKey = ref.read(aiSettingsProvider).trim().isNotEmpty;
    return AlertDialog(
      title: const Row(
        children: [
          Icon(Icons.auto_awesome, size: 20),
          SizedBox(width: 8),
          Text('Ask AI'),
        ],
      ),
      content: SizedBox(
        width: 420,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextField(
              controller: _prompt,
              autofocus: true,
              minLines: 2,
              maxLines: 4,
              decoration: const InputDecoration(
                labelText: 'Describe a calculation',
                hintText: 'e.g. 18% tip on 240 split 3 ways',
                border: OutlineInputBorder(),
              ),
              onSubmitted: (_) => _ask(),
            ),
            const SizedBox(height: 12),
            // API key: collapsed once set, expandable to change.
            if (!hasKey || _showKey)
              TextField(
                controller: _key,
                obscureText: true,
                decoration: const InputDecoration(
                  labelText: 'Anthropic API key',
                  hintText: 'sk-ant-…  (stored locally on this device)',
                  border: OutlineInputBorder(),
                ),
              )
            else
              Row(
                children: [
                  const Icon(Icons.key, size: 16),
                  const SizedBox(width: 6),
                  const Text('API key saved on this device'),
                  const Spacer(),
                  TextButton(
                    onPressed: () => setState(() => _showKey = true),
                    child: const Text('Change'),
                  ),
                ],
              ),
            if (_error != null) ...[
              const SizedBox(height: 10),
              Text(
                _error!,
                style: TextStyle(color: Theme.of(context).colorScheme.error),
              ),
            ],
            const SizedBox(height: 6),
            Text(
              'Get a key at console.anthropic.com. Calls go directly to Anthropic '
              'with your key; usage is billed to your account.',
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: _loading ? null : () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        FilledButton.icon(
          onPressed: _loading ? null : _ask,
          icon: _loading
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Icon(Icons.auto_awesome, size: 18),
          label: Text(_loading ? 'Thinking…' : 'Ask'),
        ),
      ],
    );
  }
}
