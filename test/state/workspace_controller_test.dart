import 'package:calculator2/ai/ai_commands.dart';
import 'package:calculator2/data/repository/workspace_repository.dart';
import 'package:calculator2/domain/model/workspace.dart';
import 'package:calculator2/state/document_controller.dart';
import 'package:flutter_test/flutter_test.dart';

class _MemoryRepository implements WorkspaceRepository {
  Workspace? saved;
  @override
  Future<Workspace?> load() async => saved;
  @override
  Future<void> save(Workspace workspace) async => saved = workspace;
}

Future<DocumentController> _controller(_MemoryRepository repo) async {
  final initial = await DocumentController.bootstrap(repo);
  return DocumentController(repo, initial);
}

void main() {
  test('seeds one project with one canvas', () async {
    final c = await _controller(_MemoryRepository());
    expect(c.workspace.projects.length, 1);
    expect(c.project.canvases.length, 1);
  });

  test('add / switch / rename / delete canvases', () async {
    final c = await _controller(_MemoryRepository());
    final firstCanvas = c.canvas.id;

    c.apply(const CreateCanvas('Second'));
    expect(c.project.canvases.length, 2);
    expect(c.canvas.name, 'Second'); // switched to the new canvas

    c.apply(RenameCanvas(c.canvas.id, 'Renamed'));
    expect(c.canvas.name, 'Renamed');

    c.switchCanvas(firstCanvas);
    expect(c.canvas.id, firstCanvas);

    final toDelete = c.project.canvases.last.id;
    c.apply(DeleteCanvas(toDelete));
    expect(c.project.canvases.length, 1);
  });

  test('keeps at least one canvas', () async {
    final c = await _controller(_MemoryRepository());
    c.apply(DeleteCanvas(c.canvas.id));
    expect(c.project.canvases.length, 1);
  });

  test('create / switch / delete projects', () async {
    final c = await _controller(_MemoryRepository());
    final first = c.workspace.currentProjectId;

    c.createProject('Trip');
    expect(c.workspace.projects.length, 2);
    expect(c.project.name, 'Trip'); // switched to new project

    c.switchProject(first);
    expect(c.workspace.currentProjectId, first);

    c.deleteProject(c.workspace.projects.last.id);
    expect(c.workspace.projects.length, 1);
  });

  test('persists to the repository on mutation', () async {
    final repo = _MemoryRepository();
    final c = await _controller(repo);
    c.apply(const CreateCanvas('Saved'));
    expect(repo.saved, isNotNull);
    expect(
      repo.saved!.currentProject.canvases.any((x) => x.name == 'Saved'),
      isTrue,
    );
  });
}
