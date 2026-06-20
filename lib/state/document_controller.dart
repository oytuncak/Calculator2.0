import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../ai/ai_commands.dart';
import '../data/repository/document_repository.dart';
import '../domain/graph/recompute_engine.dart';
import '../domain/model/canvas_doc.dart';
import '../domain/model/cell_value.dart';
import '../domain/model/element.dart';
import '../domain/model/element_id.dart';
import '../domain/model/project.dart';
import '../domain/serialization/document_codec.dart';

/// Immutable snapshot of the editor: the project, which canvas is active, the
/// live computed results for that canvas, and the current selection.
class DocumentState {
  const DocumentState({
    required this.project,
    required this.currentCanvasId,
    required this.results,
    this.selectedId,
  });

  final Project project;
  final ElementId currentCanvasId;
  final RecomputeResult results;
  final ElementId? selectedId;

  CanvasDoc get canvas => project.canvasById(currentCanvasId)!;

  CellValue valueFor(ElementId id) => results.valueFor(id);

  DocumentState copyWith({
    Project? project,
    ElementId? currentCanvasId,
    RecomputeResult? results,
    ElementId? selectedId,
    bool clearSelection = false,
  }) =>
      DocumentState(
        project: project ?? this.project,
        currentCanvasId: currentCanvasId ?? this.currentCanvasId,
        results: results ?? this.results,
        selectedId: clearSelection ? null : (selectedId ?? this.selectedId),
      );
}

/// Owns the document. Every mutation flows through [apply] so the UI and a
/// future AI/MCP layer share one path and recompute identically.
class DocumentController extends StateNotifier<DocumentState> {
  DocumentController(this._repository, DocumentState initial) : super(initial);

  final DocumentRepository _repository;
  final _engine = RecomputeEngine();

  /// Builds the starting state, loading any saved document or seeding a fresh
  /// welcome canvas.
  static Future<DocumentState> bootstrap(DocumentRepository repository) async {
    final loaded = await repository.load();
    final project = loaded ?? _seedProject();
    final canvas = project.canvases.first;
    return DocumentState(
      project: project,
      currentCanvasId: canvas.id,
      results: RecomputeEngine().compute(canvas),
    );
  }

  // --- command bus ---

  void apply(DocumentCommand command) {
    switch (command) {
      case AddEquation(:final x, :final y, :final rawText):
        final el = EquationElement(
            id: ElementId.generate(), x: x, y: y, rawText: rawText);
        _mutateCanvas((c) => c.upsertElement(el), select: el.id);
      case AddText(:final x, :final y, :final text):
        final el =
            TextElement(id: ElementId.generate(), x: x, y: y, text: text);
        _mutateCanvas((c) => c.upsertElement(el), select: el.id);
      case EditElement(:final id, :final rawText):
        final existing = canvas.elementById(id);
        if (existing is EquationElement) {
          _mutateCanvas((c) => c.upsertElement(existing.copyWith(rawText: rawText)));
        } else if (existing is TextElement) {
          _mutateCanvas((c) => c.upsertElement(existing.copyWith(text: rawText)));
        }
      case MoveElement(:final id, :final x, :final y):
        final existing = canvas.elementById(id);
        final moved = switch (existing) {
          EquationElement() => existing.copyWith(x: x, y: y),
          TextElement() => existing.copyWith(x: x, y: y),
          null => null,
        };
        if (moved != null) _mutateCanvas((c) => c.upsertElement(moved));
      case LinkElements(:final source, :final target):
        final src = canvas.elementById(source);
        if (src is EquationElement) {
          final sep = src.rawText.trim().isEmpty ? '' : ' ';
          _mutateCanvas((c) => c.upsertElement(
              src.copyWith(rawText: '${src.rawText}$sep@${target.value}')));
        }
      case DeleteElement(:final id):
        _mutateCanvas((c) => c.removeElement(id), clearSelection: true);
      case CreateCanvas(:final name):
        final doc = CanvasDoc(id: ElementId.generate(), name: name);
        final next = project.upsertCanvas(doc);
        _commit(next, currentCanvasId: doc.id, clearSelection: true);
    }
  }

  CanvasDoc get canvas => state.canvas;

  void select(ElementId? id) =>
      state = state.copyWith(selectedId: id, clearSelection: id == null);

  void updateView(CanvasViewState view) {
    _mutateCanvas((c) => c.copyWith(view: view), recompute: false);
  }

  // --- internals ---

  void _mutateCanvas(
    CanvasDoc Function(CanvasDoc) transform, {
    ElementId? select,
    bool clearSelection = false,
    bool recompute = true,
  }) {
    final updated = transform(canvas);
    final nextProject = project.upsertCanvas(updated);
    _commit(
      nextProject,
      results: recompute ? _engine.compute(updated) : null,
      select: select,
      clearSelection: clearSelection,
    );
  }

  void _commit(
    Project nextProject, {
    ElementId? currentCanvasId,
    RecomputeResult? results,
    ElementId? select,
    bool clearSelection = false,
  }) {
    final canvasId = currentCanvasId ?? state.currentCanvasId;
    state = DocumentState(
      project: nextProject,
      currentCanvasId: canvasId,
      results: results ??
          (currentCanvasId != null
              ? _engine.compute(nextProject.canvasById(canvasId)!)
              : state.results),
      selectedId: clearSelection ? null : (select ?? state.selectedId),
    );
    _repository.save(nextProject);
  }

  Project get project => state.project;

  static Project _seedProject() {
    final canvasId = ElementId.generate();
    final a = EquationElement(
        id: ElementId.generate(), x: 60, y: 120, rawText: '120 * 3');
    final b = EquationElement(
        id: ElementId.generate(),
        x: 60,
        y: 210,
        rawText: '@${a.id.value} + 50');
    final title = TextElement(
        id: ElementId.generate(),
        x: 60,
        y: 56,
        text: 'Welcome to Calculator 2.0',
        fontSize: 22,
        bold: true);
    return Project(
      id: ElementId.generate(),
      name: 'My Project',
      canvases: [
        CanvasDoc(
          id: canvasId,
          name: 'Canvas 1',
          elements: [title, a, b],
        ),
      ],
    );
  }
}

/// Provider scaffolding. [documentRepositoryProvider] and
/// [documentControllerProvider] are overridden in `main()` once the repository
/// and bootstrap state are ready.
final documentRepositoryProvider = Provider<DocumentRepository>(
  (ref) => SharedPrefsDocumentRepository(DocumentCodec()),
);

final documentControllerProvider =
    StateNotifierProvider<DocumentController, DocumentState>(
  (ref) => throw UnimplementedError(
    'documentControllerProvider must be overridden in main()',
  ),
);
