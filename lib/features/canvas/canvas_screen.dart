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
          const SizedBox(width: 8),
        ],
      ),
      body: const CanvasView(),
    );
  }
}
