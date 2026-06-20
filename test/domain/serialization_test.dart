import 'package:calculator2/domain/model/canvas_doc.dart';
import 'package:calculator2/domain/model/element.dart';
import 'package:calculator2/domain/model/element_id.dart';
import 'package:calculator2/domain/model/project.dart';
import 'package:calculator2/domain/serialization/document_codec.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final codec = DocumentCodec();

  test('round-trips a project through .calc2x JSON', () {
    final project = Project(
      id: ElementId('proj'),
      name: 'Budget',
      canvases: [
        CanvasDoc(
          id: ElementId('canvas'),
          name: 'Main',
          view: const CanvasViewState(offsetX: 12, offsetY: -8, scale: 1.5),
          elements: [
            EquationElement(
                id: ElementId('a'), x: 10, y: 20, rawText: '5 + 5', label: 'sum'),
            EquationElement(id: ElementId('b'), x: 0, y: 80, rawText: '@a * 2'),
            TextElement(
                id: ElementId('t'), x: 5, y: 0, text: 'Title', bold: true),
          ],
        ),
      ],
    );

    final restored = codec.decode(codec.encode(project));

    expect(restored.name, 'Budget');
    expect(restored.canvases.single.name, 'Main');
    expect(restored.canvases.single.view.scale, 1.5);

    final a = restored.canvases.single.elementById(ElementId('a'));
    expect(a, isA<EquationElement>());
    expect((a as EquationElement).rawText, '5 + 5');
    expect(a.label, 'sum');

    final t = restored.canvases.single.elementById(ElementId('t'));
    expect((t as TextElement).bold, isTrue);
  });

  test('rejects a future format version', () {
    expect(
      () => codec.decode('{"formatVersion": 999, "project": {}}'),
      throwsFormatException,
    );
  });
}
