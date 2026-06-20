import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../ai/ai_commands.dart';
import '../../domain/model/element_id.dart';
import '../../state/document_controller.dart';
import '../common/text_input_dialog.dart';

/// A horizontal row of canvas tabs for the current project, with add and
/// per-tab rename/delete.
class CanvasTabBar extends ConsumerWidget {
  const CanvasTabBar({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(documentControllerProvider);
    final controller = ref.read(documentControllerProvider.notifier);
    final scheme = Theme.of(context).colorScheme;
    final canvases = state.project.canvases;
    final currentId = state.currentCanvasId;

    return Container(
      height: 44,
      color: scheme.surfaceContainerHighest,
      child: Row(
        children: [
          Expanded(
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
              itemCount: canvases.length,
              separatorBuilder: (_, _) => const SizedBox(width: 6),
              itemBuilder: (context, i) {
                final c = canvases[i];
                final selected = c.id == currentId;
                return _Tab(
                  label: c.name,
                  selected: selected,
                  onTap: () => controller.switchCanvas(c.id),
                  onRename: () => _rename(context, controller, c.id, c.name),
                  onDelete: canvases.length > 1
                      ? () => controller.apply(DeleteCanvas(c.id))
                      : null,
                );
              },
            ),
          ),
          IconButton(
            tooltip: 'Add canvas',
            icon: const Icon(Icons.add),
            onPressed: () =>
                controller.apply(CreateCanvas('Canvas ${canvases.length + 1}')),
          ),
        ],
      ),
    );
  }

  Future<void> _rename(
    BuildContext context,
    DocumentController controller,
    ElementId id,
    String current,
  ) async {
    final name = await showTextInputDialog(
      context,
      title: 'Rename canvas',
      initialValue: current,
      confirmLabel: 'Rename',
    );
    if (name != null && name.isNotEmpty) {
      controller.apply(RenameCanvas(id, name));
    }
  }
}

class _Tab extends StatelessWidget {
  const _Tab({
    required this.label,
    required this.selected,
    required this.onTap,
    required this.onRename,
    required this.onDelete,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;
  final VoidCallback onRename;
  final VoidCallback? onDelete;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return GestureDetector(
      onTap: onTap,
      onLongPress: onRename,
      child: Container(
        padding: const EdgeInsets.only(left: 14, right: 4),
        decoration: BoxDecoration(
          color: selected ? scheme.primaryContainer : scheme.surface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: selected ? scheme.primary : scheme.outlineVariant,
          ),
        ),
        child: Row(
          children: [
            Text(
              label,
              style: TextStyle(
                fontWeight: selected ? FontWeight.w600 : FontWeight.normal,
                color: selected
                    ? scheme.onPrimaryContainer
                    : scheme.onSurfaceVariant,
              ),
            ),
            PopupMenuButton<String>(
              tooltip: 'Canvas options',
              padding: EdgeInsets.zero,
              icon: Icon(
                Icons.more_vert,
                size: 18,
                color: scheme.onSurfaceVariant,
              ),
              onSelected: (v) {
                if (v == 'rename') onRename();
                if (v == 'delete') onDelete?.call();
              },
              itemBuilder: (context) => [
                const PopupMenuItem(value: 'rename', child: Text('Rename')),
                if (onDelete != null)
                  const PopupMenuItem(value: 'delete', child: Text('Delete')),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
