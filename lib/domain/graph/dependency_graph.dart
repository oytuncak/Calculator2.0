import '../model/element_id.dart';

/// Result of a topological sort over a set of nodes.
class TopoResult {
  const TopoResult(this.order, this.cyclic);

  /// Nodes in a safe evaluation order (dependencies before dependents).
  final List<ElementId> order;

  /// Nodes that are part of a cycle and therefore could not be ordered.
  final Set<ElementId> cyclic;
}

/// Directed dependency graph: an edge `a -> b` means "a depends on b"
/// (a references b's result), so b must be evaluated before a.
///
/// Pure Dart. Used by the recompute engine to evaluate in the right order and
/// to detect circular references.
class DependencyGraph {
  final Map<ElementId, Set<ElementId>> _dependsOn = {};

  /// Replaces the full set of dependencies for [id].
  void setDependencies(ElementId id, Set<ElementId> deps) {
    _dependsOn[id] = {...deps};
  }

  Set<ElementId> dependenciesOf(ElementId id) =>
      _dependsOn[id] ?? const {};

  /// Elements that directly depend on [id] (its dependents), restricted to
  /// the known node set.
  Set<ElementId> dependentsOf(ElementId id) {
    final result = <ElementId>{};
    _dependsOn.forEach((node, deps) {
      if (deps.contains(id)) result.add(node);
    });
    return result;
  }

  void clear() => _dependsOn.clear();

  /// Kahn's algorithm restricted to [nodes]. Only edges whose endpoints are
  /// both in [nodes] are considered. Any node left with unresolved
  /// dependencies after the sort is part of a cycle.
  TopoResult topologicalSort(Set<ElementId> nodes) {
    // indegree = number of dependencies (within the node set) still unmet.
    final indegree = <ElementId, int>{};
    final dependents = <ElementId, List<ElementId>>{};

    for (final n in nodes) {
      indegree.putIfAbsent(n, () => 0);
      for (final dep in dependenciesOf(n)) {
        if (!nodes.contains(dep)) continue; // edge to outside the set: ignore
        indegree[n] = (indegree[n] ?? 0) + 1;
        dependents.putIfAbsent(dep, () => []).add(n);
      }
    }

    final queue = <ElementId>[
      for (final n in nodes)
        if ((indegree[n] ?? 0) == 0) n,
    ];
    final order = <ElementId>[];

    while (queue.isNotEmpty) {
      final n = queue.removeAt(0);
      order.add(n);
      for (final d in dependents[n] ?? const []) {
        indegree[d] = indegree[d]! - 1;
        if (indegree[d] == 0) queue.add(d);
      }
    }

    final cyclic = nodes.difference(order.toSet());
    return TopoResult(order, cyclic);
  }
}
