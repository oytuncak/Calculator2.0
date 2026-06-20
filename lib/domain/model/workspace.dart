import 'element_id.dart';
import 'project.dart';

/// The whole saved workspace: every [Project] plus which project/canvas is
/// currently open. This is the new top-level persisted unit in M2 (M1 stored a
/// single project).
class Workspace {
  Workspace({
    required this.projects,
    required this.currentProjectId,
    required this.currentCanvasId,
  });

  final List<Project> projects;
  final ElementId currentProjectId;
  final ElementId currentCanvasId;

  Project get currentProject => projectById(currentProjectId) ?? projects.first;

  Project? projectById(ElementId id) {
    for (final p in projects) {
      if (p.id == id) return p;
    }
    return null;
  }

  Workspace copyWith({
    List<Project>? projects,
    ElementId? currentProjectId,
    ElementId? currentCanvasId,
  }) => Workspace(
    projects: projects ?? this.projects,
    currentProjectId: currentProjectId ?? this.currentProjectId,
    currentCanvasId: currentCanvasId ?? this.currentCanvasId,
  );

  Workspace upsertProject(Project project) {
    final next = List<Project>.from(projects);
    final idx = next.indexWhere((p) => p.id == project.id);
    if (idx >= 0) {
      next[idx] = project;
    } else {
      next.add(project);
    }
    return copyWith(projects: next);
  }

  Workspace removeProject(ElementId id) =>
      copyWith(projects: projects.where((p) => p.id != id).toList());

  Map<String, dynamic> toJson() => {
    'projects': projects.map((p) => p.toJson()).toList(),
    'currentProjectId': currentProjectId.value,
    'currentCanvasId': currentCanvasId.value,
  };

  static Workspace fromJson(Map<String, dynamic> json) {
    final projects = ((json['projects'] as List?) ?? const [])
        .map((p) => Project.fromJson(p as Map<String, dynamic>))
        .toList();
    return Workspace(
      projects: projects,
      currentProjectId: ElementId(json['currentProjectId'] as String),
      currentCanvasId: ElementId(json['currentCanvasId'] as String),
    );
  }
}
