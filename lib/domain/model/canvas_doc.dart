import 'element.dart';
import 'element_id.dart';

/// Saved pan/zoom state of a canvas so it reopens where you left it.
class CanvasViewState {
  const CanvasViewState({this.offsetX = 0, this.offsetY = 0, this.scale = 1});

  final double offsetX;
  final double offsetY;
  final double scale;

  CanvasViewState copyWith({double? offsetX, double? offsetY, double? scale}) =>
      CanvasViewState(
        offsetX: offsetX ?? this.offsetX,
        offsetY: offsetY ?? this.offsetY,
        scale: scale ?? this.scale,
      );

  Map<String, dynamic> toJson() => {
    'offsetX': offsetX,
    'offsetY': offsetY,
    'scale': scale,
  };

  static CanvasViewState fromJson(Map<String, dynamic> json) => CanvasViewState(
    offsetX: (json['offsetX'] as num?)?.toDouble() ?? 0,
    offsetY: (json['offsetY'] as num?)?.toDouble() ?? 0,
    scale: (json['scale'] as num?)?.toDouble() ?? 1,
  );
}

/// One canvas / tab: an ordered collection of elements plus its view state.
class CanvasDoc {
  CanvasDoc({
    required this.id,
    required this.name,
    List<CanvasElement>? elements,
    this.view = const CanvasViewState(),
  }) : elements = List.unmodifiable(elements ?? const []);

  final ElementId id;
  final String name;
  final List<CanvasElement> elements;
  final CanvasViewState view;

  CanvasElement? elementById(ElementId id) {
    for (final e in elements) {
      if (e.id == id) return e;
    }
    return null;
  }

  CanvasDoc copyWith({
    String? name,
    List<CanvasElement>? elements,
    CanvasViewState? view,
  }) => CanvasDoc(
    id: id,
    name: name ?? this.name,
    elements: elements ?? this.elements,
    view: view ?? this.view,
  );

  /// Returns a copy with [element] added or, if an element with the same id
  /// already exists, replaced in place.
  CanvasDoc upsertElement(CanvasElement element) {
    final next = List<CanvasElement>.from(elements);
    final idx = next.indexWhere((e) => e.id == element.id);
    if (idx >= 0) {
      next[idx] = element;
    } else {
      next.add(element);
    }
    return copyWith(elements: next);
  }

  CanvasDoc removeElement(ElementId id) =>
      copyWith(elements: elements.where((e) => e.id != id).toList());

  Map<String, dynamic> toJson() => {
    'id': id.value,
    'name': name,
    'view': view.toJson(),
    'elements': elements.map((e) => e.toJson()).toList(),
  };

  static CanvasDoc fromJson(Map<String, dynamic> json) => CanvasDoc(
    id: ElementId(json['id'] as String),
    name: json['name'] as String? ?? 'Canvas',
    view: json['view'] == null
        ? const CanvasViewState()
        : CanvasViewState.fromJson(json['view'] as Map<String, dynamic>),
    elements: ((json['elements'] as List?) ?? const [])
        .map((e) => CanvasElement.fromJson(e as Map<String, dynamic>))
        .toList(),
  );
}
