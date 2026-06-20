import 'element_id.dart';

/// Base type for everything that lives on the canvas.
///
/// Pure Dart: position/size are plain doubles (not Flutter `Offset`/`Size`) so
/// the domain has zero Flutter coupling. Only source-of-truth is stored;
/// computed results are derived by the recompute engine, never persisted here.
sealed class CanvasElement {
  const CanvasElement({
    required this.id,
    required this.x,
    required this.y,
    required this.width,
    required this.height,
  });

  final ElementId id;
  final double x;
  final double y;
  final double width;
  final double height;

  Map<String, dynamic> toJson();

  static CanvasElement fromJson(Map<String, dynamic> json) {
    final type = json['type'] as String;
    return switch (type) {
      'equation' => EquationElement.fromJson(json),
      'text' => TextElement.fromJson(json),
      _ => throw FormatException('Unknown element type "$type"'),
    };
  }
}

/// An equation the user types. [rawText] is the single source of truth; the
/// result is computed live and never stored. References to other elements are
/// embedded in [rawText] as `@<id>` tokens.
class EquationElement extends CanvasElement {
  const EquationElement({
    required super.id,
    required super.x,
    required super.y,
    super.width = 220,
    super.height = 56,
    this.rawText = '',
    this.label,
  });

  final String rawText;

  /// Optional human-friendly name shown on the result pill / used in exports.
  final String? label;

  EquationElement copyWith({
    double? x,
    double? y,
    double? width,
    double? height,
    String? rawText,
    String? label,
  }) =>
      EquationElement(
        id: id,
        x: x ?? this.x,
        y: y ?? this.y,
        width: width ?? this.width,
        height: height ?? this.height,
        rawText: rawText ?? this.rawText,
        label: label ?? this.label,
      );

  @override
  Map<String, dynamic> toJson() => {
        'type': 'equation',
        'id': id.value,
        'x': x,
        'y': y,
        'width': width,
        'height': height,
        'rawText': rawText,
        if (label != null) 'label': label,
      };

  static EquationElement fromJson(Map<String, dynamic> json) => EquationElement(
        id: ElementId(json['id'] as String),
        x: (json['x'] as num).toDouble(),
        y: (json['y'] as num).toDouble(),
        width: (json['width'] as num?)?.toDouble() ?? 220,
        height: (json['height'] as num?)?.toDouble() ?? 56,
        rawText: json['rawText'] as String? ?? '',
        label: json['label'] as String?,
      );
}

/// A free text note / title / label placed on the canvas.
class TextElement extends CanvasElement {
  const TextElement({
    required super.id,
    required super.x,
    required super.y,
    super.width = 240,
    super.height = 48,
    this.text = '',
    this.fontSize = 18,
    this.bold = false,
  });

  final String text;
  final double fontSize;
  final bool bold;

  TextElement copyWith({
    double? x,
    double? y,
    double? width,
    double? height,
    String? text,
    double? fontSize,
    bool? bold,
  }) =>
      TextElement(
        id: id,
        x: x ?? this.x,
        y: y ?? this.y,
        width: width ?? this.width,
        height: height ?? this.height,
        text: text ?? this.text,
        fontSize: fontSize ?? this.fontSize,
        bold: bold ?? this.bold,
      );

  @override
  Map<String, dynamic> toJson() => {
        'type': 'text',
        'id': id.value,
        'x': x,
        'y': y,
        'width': width,
        'height': height,
        'text': text,
        'fontSize': fontSize,
        'bold': bold,
      };

  static TextElement fromJson(Map<String, dynamic> json) => TextElement(
        id: ElementId(json['id'] as String),
        x: (json['x'] as num).toDouble(),
        y: (json['y'] as num).toDouble(),
        width: (json['width'] as num?)?.toDouble() ?? 240,
        height: (json['height'] as num?)?.toDouble() ?? 48,
        text: json['text'] as String? ?? '',
        fontSize: (json['fontSize'] as num?)?.toDouble() ?? 18,
        bold: json['bold'] as bool? ?? false,
      );
}
