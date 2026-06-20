import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/export/file_export_service.dart';
import '../../data/export/xlsx_exporter.dart';
import '../../state/document_controller.dart';
import '../../state/settings_controller.dart';
import '../projects/projects_drawer.dart';
import 'canvas_tab_bar.dart';
import 'canvas_view.dart';

/// Top-level screen: app bar (project/canvas name, export, dark-mode, about),
/// a projects drawer, the canvas tab bar, and the infinite canvas.
class CanvasScreen extends ConsumerWidget {
  const CanvasScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(documentControllerProvider);
    final themeMode = ref.watch(settingsControllerProvider);
    final isDark =
        themeMode == ThemeMode.dark ||
        (themeMode == ThemeMode.system &&
            MediaQuery.platformBrightnessOf(context) == Brightness.dark);

    return Scaffold(
      drawer: const ProjectsDrawer(),
      appBar: AppBar(
        titleSpacing: 8,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              state.project.name,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
            ),
            Text(
              state.canvas.name,
              style: TextStyle(
                fontSize: 12,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            tooltip: 'Export to Excel',
            icon: const Icon(Icons.table_view),
            onPressed: () => _exportXlsx(context, ref),
          ),
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
          const SizedBox(width: 4),
        ],
        bottom: const PreferredSize(
          preferredSize: Size.fromHeight(44),
          child: CanvasTabBar(),
        ),
      ),
      body: const CanvasView(),
    );
  }

  Future<void> _exportXlsx(BuildContext context, WidgetRef ref) async {
    final state = ref.read(documentControllerProvider);
    final messenger = ScaffoldMessenger.of(context);
    try {
      final bytes = XlsxExporter().exportBytes(state.canvas, state.results);
      final fileName = '${state.project.name}-${state.canvas.name}'.replaceAll(
        ' ',
        '_',
      );
      await FileExportService().saveXlsx(fileName, bytes);
      messenger.showSnackBar(
        SnackBar(content: Text('Exported "$fileName.xlsx"')),
      );
    } catch (e) {
      messenger.showSnackBar(SnackBar(content: Text('Export failed: $e')));
    }
  }

  void _showAbout(BuildContext context) {
    showAboutDialog(
      context: context,
      applicationName: 'Calculator 2.0',
      applicationVersion: 'Milestone 2',
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
