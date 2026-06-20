import 'package:calculator2/ai/ai_commands.dart';
import 'package:calculator2/data/repository/workspace_repository.dart';
import 'package:calculator2/domain/model/element.dart';
import 'package:calculator2/domain/model/workspace.dart';
import 'package:calculator2/state/document_controller.dart';
import 'package:flutter_test/flutter_test.dart';

class _MemoryRepository implements WorkspaceRepository {
  Workspace? saved;
  @override
  Future<Workspace?> load() async => saved;
  @override
  Future<void> save(Workspace workspace) async => saved = workspace;
}

Future<DocumentController> _controller() async {
  final repo = _MemoryRepository();
  final initial = await DocumentController.bootstrap(repo);
  return DocumentController(repo, initial);
}

ChartElement _chart(DocumentController c) =>
    c.canvas.elements.whereType<ChartElement>().first;

void main() {
  test('add chart, add sources, set type, remove source', () async {
    final c = await _controller();
    // Two equations to chart.
    c.apply(const AddEquation(x: 0, y: 0, rawText: '10'));
    c.apply(const AddEquation(x: 0, y: 60, rawText: '20'));
    final equations = c.canvas.elements.whereType<EquationElement>().toList();

    c.apply(const AddChart(x: 0, y: 200));
    final chartId = _chart(c).id;
    expect(_chart(c).sources, isEmpty);
    expect(_chart(c).chartType, ChartType.bar);

    c.apply(AddChartSource(chart: chartId, source: equations[0].id));
    c.apply(AddChartSource(chart: chartId, source: equations[1].id));
    expect(_chart(c).sources.length, 2);

    // Adding the same source again is a no-op.
    c.apply(AddChartSource(chart: chartId, source: equations[0].id));
    expect(_chart(c).sources.length, 2);

    c.apply(SetChartType(chartId, ChartType.line));
    expect(_chart(c).chartType, ChartType.line);

    c.apply(RemoveChartSource(chart: chartId, source: equations[0].id));
    expect(_chart(c).sources, [equations[1].id]);
  });

  test('chart can be moved like any element', () async {
    final c = await _controller();
    c.apply(const AddChart(x: 0, y: 0));
    final id = _chart(c).id;
    c.apply(MoveElement(id, 120, 240));
    expect(_chart(c).x, 120);
    expect(_chart(c).y, 240);
  });

  test('charts are ignored by the recompute engine (no result)', () async {
    final c = await _controller();
    c.apply(const AddChart(x: 0, y: 0));
    final id = _chart(c).id;
    // A chart has no computed value; valueFor returns empty, not an error.
    expect(c.state.valueFor(id).isError, isFalse);
  });
}
