import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../state/document_controller.dart';
import '../common/text_input_dialog.dart';

/// Side drawer listing all projects: select, create, rename, delete.
class ProjectsDrawer extends ConsumerWidget {
  const ProjectsDrawer({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(documentControllerProvider);
    final controller = ref.read(documentControllerProvider.notifier);
    final projects = state.workspace.projects;
    final currentId = state.workspace.currentProjectId;

    return Drawer(
      child: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 8, 8),
              child: Row(
                children: [
                  Text(
                    'Projects',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const Spacer(),
                  IconButton(
                    tooltip: 'New project',
                    icon: const Icon(Icons.add),
                    onPressed: () async {
                      final name = await showTextInputDialog(
                        context,
                        title: 'New project',
                        confirmLabel: 'Create',
                      );
                      if (name != null && name.isNotEmpty) {
                        controller.createProject(name);
                      }
                    },
                  ),
                ],
              ),
            ),
            const Divider(height: 1),
            Expanded(
              child: ListView.builder(
                itemCount: projects.length,
                itemBuilder: (context, i) {
                  final p = projects[i];
                  final selected = p.id == currentId;
                  return ListTile(
                    selected: selected,
                    leading: Icon(
                      selected ? Icons.folder_open : Icons.folder_outlined,
                    ),
                    title: Text(p.name),
                    subtitle: Text(
                      '${p.canvases.length} canvas${p.canvases.length == 1 ? '' : 'es'}',
                    ),
                    onTap: () {
                      controller.switchProject(p.id);
                      Navigator.of(context).pop();
                    },
                    trailing: PopupMenuButton<String>(
                      onSelected: (v) async {
                        if (v == 'rename') {
                          final name = await showTextInputDialog(
                            context,
                            title: 'Rename project',
                            initialValue: p.name,
                            confirmLabel: 'Rename',
                          );
                          if (name != null && name.isNotEmpty) {
                            controller.renameProject(p.id, name);
                          }
                        } else if (v == 'delete') {
                          controller.deleteProject(p.id);
                        }
                      },
                      itemBuilder: (context) => [
                        const PopupMenuItem(
                          value: 'rename',
                          child: Text('Rename'),
                        ),
                        if (projects.length > 1)
                          const PopupMenuItem(
                            value: 'delete',
                            child: Text('Delete'),
                          ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
