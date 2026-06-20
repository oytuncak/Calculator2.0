import 'canvas_doc.dart';
import 'element_id.dart';

/// Top of the hierarchy: a Project groups one or more canvases (tabs).
///
/// In M1 a project holds the canvases; the Projects browser UI and multi-tab
/// switching build on this in M2.
class Project {
  Project({required this.id, required this.name, List<CanvasDoc>? canvases})
    : canvases = List.unmodifiable(canvases ?? const []);

  final ElementId id;
  final String name;
  final List<CanvasDoc> canvases;

  CanvasDoc? canvasById(ElementId id) {
    for (final c in canvases) {
      if (c.id == id) return c;
    }
    return null;
  }

  Project copyWith({String? name, List<CanvasDoc>? canvases}) => Project(
    id: id,
    name: name ?? this.name,
    canvases: canvases ?? this.canvases,
  );

  Project upsertCanvas(CanvasDoc canvas) {
    final next = List<CanvasDoc>.from(canvases);
    final idx = next.indexWhere((c) => c.id == canvas.id);
    if (idx >= 0) {
      next[idx] = canvas;
    } else {
      next.add(canvas);
    }
    return copyWith(canvases: next);
  }

  Map<String, dynamic> toJson() => {
    'id': id.value,
    'name': name,
    'canvases': canvases.map((c) => c.toJson()).toList(),
  };

  static Project fromJson(Map<String, dynamic> json) => Project(
    id: ElementId(json['id'] as String),
    name: json['name'] as String? ?? 'Project',
    canvases: ((json['canvases'] as List?) ?? const [])
        .map((c) => CanvasDoc.fromJson(c as Map<String, dynamic>))
        .toList(),
  );
}
