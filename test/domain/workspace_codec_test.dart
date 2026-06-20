import 'package:calculator2/domain/model/canvas_doc.dart';
import 'package:calculator2/domain/model/element.dart';
import 'package:calculator2/domain/model/element_id.dart';
import 'package:calculator2/domain/model/project.dart';
import 'package:calculator2/domain/model/workspace.dart';
import 'package:calculator2/domain/serialization/workspace_codec.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final codec = WorkspaceCodec();

  test('round-trips a multi-project, multi-canvas workspace', () {
    final workspace = Workspace(
      projects: [
        Project(
          id: ElementId('p1'),
          name: 'Budget',
          canvases: [
            CanvasDoc(
              id: ElementId('c1'),
              name: 'Main',
              view: const CanvasViewState(offsetX: 5, offsetY: -3, scale: 1.25),
              elements: [
                EquationElement(
                  id: ElementId('a'),
                  x: 10,
                  y: 20,
                  rawText: '5 + 5',
                ),
                EquationElement(
                  id: ElementId('b'),
                  x: 0,
                  y: 80,
                  rawText: '@a * 2',
                ),
                TextElement(
                  id: ElementId('t'),
                  x: 5,
                  y: 0,
                  text: 'Hi',
                  bold: true,
                ),
              ],
            ),
            CanvasDoc(id: ElementId('c2'), name: 'Scratch'),
          ],
        ),
        Project(
          id: ElementId('p2'),
          name: 'Trip',
          canvases: [CanvasDoc(id: ElementId('c3'), name: 'Canvas 1')],
        ),
      ],
      currentProjectId: ElementId('p2'),
      currentCanvasId: ElementId('c3'),
    );

    final restored = codec.decode(codec.encode(workspace));

    expect(restored.projects.length, 2);
    expect(restored.currentProjectId, ElementId('p2'));
    expect(restored.currentCanvasId, ElementId('c3'));

    final budget = restored.projectById(ElementId('p1'))!;
    expect(budget.canvases.length, 2);
    expect(budget.canvases.first.view.scale, 1.25);
    final b = budget.canvases.first.elementById(ElementId('b'));
    expect((b as EquationElement).rawText, '@a * 2');
  });

  test('rejects a future format version', () {
    expect(
      () => codec.decode('{"formatVersion": 999, "workspace": {}}'),
      throwsFormatException,
    );
  });
}
