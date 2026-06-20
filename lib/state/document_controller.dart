import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../ai/ai_commands.dart';
import '../data/repository/workspace_repository.dart';
import '../domain/graph/recompute_engine.dart';
import '../domain/model/canvas_doc.dart';
import '../domain/model/cell_value.dart';
import '../domain/model/element.dart';
import '../domain/model/element_id.dart';
import '../domain/model/project.dart';
import '../domain/model/workspace.dart';
import '../domain/serialization/workspace_codec.dart';

/// Immutable snapshot of the editor: the workspace (all projects), the live
/// computed results for the current canvas, and the current selection.
class DocumentState {
  const DocumentState({
    required this.workspace,
    required this.results,
    this.selectedId,
  });

  final Workspace workspace;
  final RecomputeResult results;
  final ElementId? selectedId;

  Project get project => workspace.currentProject;

  CanvasDoc get canvas =>
      project.canvasById(workspace.currentCanvasId) ?? project.canvases.first;

  ElementId get currentCanvasId => canvas.id;

  CellValue valueFor(ElementId id) => results.valueFor(id);

  DocumentState copyWith({
    Workspace? workspace,
    RecomputeResult? results,
    ElementId? selectedId,
    bool clearSelection = false,
  }) => DocumentState(
    workspace: workspace ?? this.workspace,
    results: results ?? this.results,
    selectedId: clearSelection ? null : (selectedId ?? this.selectedId),
  );
}

/// Owns the workspace. Element/canvas mutations flow through [apply] (the
/// command bus shared with the future AI/MCP layer); project- and view-level
/// operations are dedicated methods.
class DocumentController extends StateNotifier<DocumentState> {
  DocumentController(this._repository, DocumentState initial) : super(initial);

  final WorkspaceRepository _repository;
  final _engine = RecomputeEngine();

  static Future<DocumentState> bootstrap(WorkspaceRepository repository) async {
    final workspace = await repository.load() ?? _seedWorkspace();
    return DocumentState(
      workspace: workspace,
      results: RecomputeEngine().compute(
        workspace.currentProject.canvasById(workspace.currentCanvasId) ??
            workspace.currentProject.canvases.first,
      ),
    );
  }

  // --- command bus (element + canvas ops on the current project/canvas) ---

  void apply(DocumentCommand command) {
    switch (command) {
      case AddEquation(:final x, :final y, :final rawText):
        final el = EquationElement(
          id: ElementId.generate(),
          x: x,
          y: y,
          rawText: rawText,
        );
        _updateCanvas((c) => c.upsertElement(el), select: el.id);
      case AddText(:final x, :final y, :final text):
        final el = TextElement(
          id: ElementId.generate(),
          x: x,
          y: y,
          text: text,
        );
        _updateCanvas((c) => c.upsertElement(el), select: el.id);
      case EditElement(:final id, :final rawText):
        final existing = canvas.elementById(id);
        if (existing is EquationElement) {
          _updateCanvas(
            (c) => c.upsertElement(existing.copyWith(rawText: rawText)),
          );
        } else if (existing is TextElement) {
          _updateCanvas(
            (c) => c.upsertElement(existing.copyWith(text: rawText)),
          );
        }
      case MoveElement(:final id, :final x, :final y):
        final existing = canvas.elementById(id);
        final moved = switch (existing) {
          EquationElement() => existing.copyWith(x: x, y: y),
          TextElement() => existing.copyWith(x: x, y: y),
          ChartElement() => existing.copyWith(x: x, y: y),
          null => null,
        };
        if (moved != null) _updateCanvas((c) => c.upsertElement(moved));
      case LinkElements(:final source, :final target):
        final src = canvas.elementById(source);
        if (src is EquationElement) {
          final sep = src.rawText.trim().isEmpty ? '' : ' ';
          _updateCanvas(
            (c) => c.upsertElement(
              src.copyWith(rawText: '${src.rawText}$sep@${target.value}'),
            ),
          );
        }
      case DeleteElement(:final id):
        _updateCanvas((c) => c.removeElement(id), clearSelection: true);
      case CreateCanvas(:final name):
        final doc = CanvasDoc(id: ElementId.generate(), name: name);
        final nextProject = project.upsertCanvas(doc);
        _commit(
          workspace
              .upsertProject(nextProject)
              .copyWith(currentCanvasId: doc.id),
          clearSelection: true,
        );
      case RenameCanvas(:final id, :final name):
        final target = project.canvasById(id);
        if (target != null) {
          _commit(
            workspace.upsertProject(
              project.upsertCanvas(target.copyWith(name: name)),
            ),
          );
        }
      case DeleteCanvas(:final id):
        _deleteCanvas(id);
      case AddChart(:final x, :final y):
        final el = ChartElement(id: ElementId.generate(), x: x, y: y);
        _updateCanvas((c) => c.upsertElement(el), select: el.id);
      case AddChartSource(:final chart, :final source):
        final el = canvas.elementById(chart);
        if (el is ChartElement && !el.sources.contains(source)) {
          _updateCanvas(
            (c) =>
                c.upsertElement(el.copyWith(sources: [...el.sources, source])),
          );
        }
      case RemoveChartSource(:final chart, :final source):
        final el = canvas.elementById(chart);
        if (el is ChartElement) {
          _updateCanvas(
            (c) => c.upsertElement(
              el.copyWith(
                sources: el.sources.where((s) => s != source).toList(),
              ),
            ),
          );
        }
      case SetChartType(:final chart, :final chartType):
        final el = canvas.elementById(chart);
        if (el is ChartElement) {
          _updateCanvas(
            (c) => c.upsertElement(el.copyWith(chartType: chartType)),
          );
        }
    }
  }

  CanvasDoc get canvas => state.canvas;
  Project get project => state.project;
  Workspace get workspace => state.workspace;

  void select(ElementId? id) =>
      state = state.copyWith(selectedId: id, clearSelection: id == null);

  void updateView(CanvasViewState view) =>
      _updateCanvas((c) => c.copyWith(view: view), recompute: false);

  // --- canvas / project navigation (UI-level) ---

  void switchCanvas(ElementId id) {
    if (project.canvasById(id) == null) return;
    _commit(workspace.copyWith(currentCanvasId: id), clearSelection: true);
  }

  void switchProject(ElementId id) {
    final p = workspace.projectById(id);
    if (p == null) return;
    _commit(
      workspace.copyWith(
        currentProjectId: id,
        currentCanvasId: p.canvases.first.id,
      ),
      clearSelection: true,
    );
  }

  void createProject(String name) {
    final canvasId = ElementId.generate();
    final p = Project(
      id: ElementId.generate(),
      name: name,
      canvases: [CanvasDoc(id: canvasId, name: 'Canvas 1')],
    );
    _commit(
      workspace
          .upsertProject(p)
          .copyWith(currentProjectId: p.id, currentCanvasId: canvasId),
      clearSelection: true,
    );
  }

  void renameProject(ElementId id, String name) {
    final p = workspace.projectById(id);
    if (p == null) return;
    _commit(workspace.upsertProject(p.copyWith(name: name)));
  }

  void deleteProject(ElementId id) {
    if (workspace.projects.length <= 1) return; // keep at least one project
    var next = workspace.removeProject(id);
    if (id == workspace.currentProjectId) {
      final p = next.projects.first;
      next = next.copyWith(
        currentProjectId: p.id,
        currentCanvasId: p.canvases.first.id,
      );
    }
    _commit(next, clearSelection: true);
  }

  // --- internals ---

  void _deleteCanvas(ElementId id) {
    if (project.canvases.length <= 1) return; // keep at least one canvas
    final remaining = project.canvases.where((c) => c.id != id).toList();
    final nextProject = project.copyWith(canvases: remaining);
    var next = workspace.upsertProject(nextProject);
    if (id == workspace.currentCanvasId) {
      next = next.copyWith(currentCanvasId: remaining.first.id);
    }
    _commit(next, clearSelection: true);
  }

  void _updateCanvas(
    CanvasDoc Function(CanvasDoc) transform, {
    ElementId? select,
    bool clearSelection = false,
    bool recompute = true,
  }) {
    final updated = transform(canvas);
    final nextWorkspace = workspace.upsertProject(
      project.upsertCanvas(updated),
    );
    _commit(
      nextWorkspace,
      results: recompute ? _engine.compute(updated) : null,
      select: select,
      clearSelection: clearSelection,
    );
  }

  void _commit(
    Workspace nextWorkspace, {
    RecomputeResult? results,
    ElementId? select,
    bool clearSelection = false,
  }) {
    final canvas =
        nextWorkspace.currentProject.canvasById(
          nextWorkspace.currentCanvasId,
        ) ??
        nextWorkspace.currentProject.canvases.first;
    state = DocumentState(
      workspace: nextWorkspace,
      results: results ?? _engine.compute(canvas),
      selectedId: clearSelection ? null : (select ?? state.selectedId),
    );
    _repository.save(nextWorkspace);
  }

  static Workspace _seedWorkspace() {
    final canvasId = ElementId.generate();
    final a = EquationElement(
      id: ElementId.generate(),
      x: 60,
      y: 120,
      rawText: '120 * 3',
    );
    final b = EquationElement(
      id: ElementId.generate(),
      x: 60,
      y: 210,
      rawText: '@${a.id.value} + 50',
    );
    final title = TextElement(
      id: ElementId.generate(),
      x: 60,
      y: 56,
      text: 'Welcome to Calculator 2.0',
      fontSize: 22,
      bold: true,
    );
    final project = Project(
      id: ElementId.generate(),
      name: 'My Project',
      canvases: [
        CanvasDoc(id: canvasId, name: 'Canvas 1', elements: [title, a, b]),
      ],
    );
    return Workspace(
      projects: [project],
      currentProjectId: project.id,
      currentCanvasId: canvasId,
    );
  }
}

/// Provider scaffolding. Both providers are overridden in `main()` once the
/// repository and bootstrap state are ready.
final workspaceRepositoryProvider = Provider<WorkspaceRepository>(
  (ref) => SharedPrefsWorkspaceRepository(WorkspaceCodec()),
);

final documentControllerProvider =
    StateNotifierProvider<DocumentController, DocumentState>(
      (ref) => throw UnimplementedError(
        'documentControllerProvider must be overridden in main()',
      ),
    );
