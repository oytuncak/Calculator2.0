import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../state/document_controller.dart';
import '../../state/settings_controller.dart';
import 'canvas_view.dart';

/// Top-level screen: app bar (project/canvas name + dark-mode toggle) over the
/// infinite canvas.
class CanvasScreen extends ConsumerWidget {
  const CanvasScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(documentControllerProvider);
    final themeMode = ref.watch(settingsControllerProvider);
    final isDark = themeMode == ThemeMode.dark ||
        (themeMode == ThemeMode.system &&
            MediaQuery.platformBrightnessOf(context) == Brightness.dark);

    return Scaffold(
      appBar: AppBar(
        titleSpacing: 16,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(state.project.name,
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
            Text(state.canvas.name,
                style: TextStyle(
                    fontSize: 12,
                    color: Theme.of(context).colorScheme.onSurfaceVariant)),
          ],
        ),
        actions: [
          IconButton(
            tooltip: isDark ? 'Light mode' : 'Dark mode',
            icon: Icon(isDark ? Icons.light_mode : Icons.dark_mode),
            onPressed: () =>
                ref.read(settingsControllerProvider.notifier).toggleDark(),
          ),
          IconButton(
            tooltip: 'About',
            icon: const Icon(Icons.info_outline),
            onPressed: () => _showAbout(context),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: const CanvasView(),
    );
  }

  void _showAbout(BuildContext context) {
    showAboutDialog(
      context: context,
      applicationName: 'Calculator 2.0',
      applicationVersion: 'Milestone 1',
      applicationLegalese: 'Developed by Gastronaut',
      children: const [
        SizedBox(height: 12),
        Text('A canvas calculator with live, linked results.'),
        SizedBox(height: 8),
        Text('Developed by Gastronaut'),
      ],
    );
  }
}
