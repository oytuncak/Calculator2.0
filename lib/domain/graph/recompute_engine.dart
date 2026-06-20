import '../engine/eval_context.dart';
import '../engine/eval_error.dart';
import '../engine/evaluator.dart';
import '../engine/expr.dart';
import '../engine/parser.dart';
import '../model/canvas_doc.dart';
import '../model/cell_value.dart';
import '../model/element.dart';
import '../model/element_id.dart';
import 'dependency_graph.dart';

/// Output of a full canvas recompute: every equation's [CellValue] plus the
/// dependency graph that produced it (handy for drawing link lines).
class RecomputeResult {
  const RecomputeResult(this.values, this.graph);

  final Map<ElementId, CellValue> values;
  final DependencyGraph graph;

  CellValue valueFor(ElementId id) => values[id] ?? const EmptyValue();
}

/// Computes live results for every equation on a canvas.
///
/// Strategy: parse each equation, build the dependency graph from `@id`
/// references, topologically sort, then evaluate in order so every reference
/// sees a fresh input. Cyclic equations resolve to a circular-reference error
/// while the rest of the canvas keeps computing.
///
/// A full recompute is O(n) in the number of equations, which is ample for M1.
/// The same graph supports incremental (affected-only) recompute later.
class RecomputeEngine {
  RecomputeResult compute(CanvasDoc doc) {
    final equations = <ElementId, EquationElement>{
      for (final e in doc.elements)
        if (e is EquationElement) e.id: e,
    };

    final asts = <ElementId, Expr>{};
    final values = <ElementId, CellValue>{};
    final graph = DependencyGraph();

    // Parse every equation; record parse errors and blank cells up front.
    for (final entry in equations.entries) {
      final raw = entry.value.rawText.trim();
      if (raw.isEmpty) {
        values[entry.key] = const EmptyValue();
        graph.setDependencies(entry.key, const {});
        continue;
      }
      try {
        final expr = Parser.fromSource(raw).parse();
        asts[entry.key] = expr;
        final refs = collectReferences(expr)
            .map(ElementId.new)
            .where(equations.containsKey)
            .toSet();
        graph.setDependencies(entry.key, refs);
      } on EvalError catch (e) {
        values[entry.key] = ErrorValue(e);
        graph.setDependencies(entry.key, const {});
      }
    }

    // Order the parsed (non-error) equations; flag cycles.
    final toEvaluate = asts.keys.toSet();
    final topo = graph.topologicalSort(toEvaluate);
    for (final id in topo.cyclic) {
      values[id] = const ErrorValue(EvalError.circularReference());
    }

    // Evaluate in dependency order.
    final context = _MapEvalContext(values, equations.keys.toSet());
    for (final id in topo.order) {
      values[id] = Evaluator(context).evaluate(asts[id]!);
    }

    return RecomputeResult(values, graph);
  }
}

/// Resolves references from an in-progress results map. Because evaluation
/// happens in topological order, a referenced value is always already present.
class _MapEvalContext implements EvalContext {
  _MapEvalContext(this._values, this._known);

  final Map<ElementId, CellValue> _values;
  final Set<ElementId> _known;

  @override
  CellValue resolveReference(String elementId) {
    final id = ElementId(elementId);
    if (!_known.contains(id)) {
      return ErrorValue(
        EvalError.unknownReference('No element "@$elementId"'),
      );
    }
    return _values[id] ?? const EmptyValue();
  }
}
