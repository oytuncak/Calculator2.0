import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../ai/ai_commands.dart';
import '../../app/theme.dart';
import '../../domain/model/canvas_doc.dart';
import '../../domain/model/element.dart';
import '../../domain/model/element_id.dart';
import '../../state/document_controller.dart';
import 'canvas_painters.dart';
import 'element_widgets/equation_widget.dart';
import 'element_widgets/text_widget.dart';

/// The infinite, pan/zoom canvas holding all elements plus the add-element
/// controls.
class CanvasView extends ConsumerStatefulWidget {
  const CanvasView({super.key});

  @override
  ConsumerState<CanvasView> createState() => _CanvasViewState();
}

class _CanvasViewState extends ConsumerState<CanvasView> {
  static const double _canvasSize = 4000;

  final _transform = TransformationController();
  Size _viewport = Size.zero;
  bool _restoredView = false;

  @override
  void dispose() {
    _transform.dispose();
    super.dispose();
  }

  double get _scale => _transform.value.getMaxScaleOnAxis();

  DocumentController get _controller =>
      ref.read(documentControllerProvider.notifier);

  void _restoreView(CanvasViewState view) {
    if (_restoredView) return;
    _restoredView = true;
    _transform.value = Matrix4.identity()
      ..translateByDouble(view.offsetX, view.offsetY, 0, 1)
      ..scaleByDouble(view.scale, view.scale, view.scale, 1);
  }

  void _persistView() {
    final m = _transform.value;
    final t = m.getTranslation();
    _controller.updateView(
      CanvasViewState(offsetX: t.x, offsetY: t.y, scale: m.getMaxScaleOnAxis()),
    );
  }

  Offset _sceneCenter() {
    if (_viewport == Size.zero) return const Offset(200, 200);
    return _transform.toScene(
      Offset(_viewport.width / 2, _viewport.height / 2),
    );
  }

  void _addEquation() {
    final c = _sceneCenter();
    _controller.apply(AddEquation(x: c.dx - 110, y: c.dy - 40));
  }

  void _addText() {
    final c = _sceneCenter();
    _controller.apply(AddText(x: c.dx - 110, y: c.dy - 20, text: ''));
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(documentControllerProvider);
    final canvas = state.canvas;
    _restoreView(canvas.view);

    final bounds = <ElementId, Rect>{
      for (final e in canvas.elements)
        e.id: Rect.fromLTWH(e.x, e.y, e.width, e.height),
    };

    return Stack(
      children: [
        LayoutBuilder(
          builder: (context, constraints) {
            _viewport = constraints.biggest;
            return InteractiveViewer(
              transformationController: _transform,
              constrained: false,
              minScale: 0.3,
              maxScale: 4,
              boundaryMargin: const EdgeInsets.all(2000),
              onInteractionEnd: (_) => _persistView(),
              child: SizedBox(
                width: _canvasSize,
                height: _canvasSize,
                child: Stack(
                  children: [
                    // Tap empty space to deselect.
                    Positioned.fill(
                      child: GestureDetector(
                        behavior: HitTestBehavior.translucent,
                        onTap: () => _controller.select(null),
                        child: CustomPaint(
                          painter: GridPainter(
                            color: AppTheme.gridLine(context),
                          ),
                        ),
                      ),
                    ),
                    Positioned.fill(
                      child: IgnorePointer(
                        child: CustomPaint(
                          painter: LinkPainter(
                            bounds: bounds,
                            graph: state.results.graph,
                            color: AppTheme.linkLine(context),
                          ),
                        ),
                      ),
                    ),
                    for (final element in canvas.elements)
                      Positioned(
                        left: element.x,
                        top: element.y,
                        child: _elementWidget(element, state),
                      ),
                  ],
                ),
              ),
            );
          },
        ),
        Positioned(
          right: 16,
          bottom: 16,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              FloatingActionButton.small(
                heroTag: 'addText',
                tooltip: 'Add text note',
                onPressed: _addText,
                child: const Icon(Icons.text_fields),
              ),
              const SizedBox(height: 12),
              FloatingActionButton.extended(
                heroTag: 'addEquation',
                tooltip: 'Add equation',
                onPressed: _addEquation,
                icon: const Icon(Icons.add),
                label: const Text('Equation'),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _elementWidget(CanvasElement element, DocumentState state) {
    final selected = state.selectedId == element.id;
    return switch (element) {
      EquationElement() => EquationWidget(
        element: element,
        value: state.valueFor(element.id),
        selected: selected,
        scaleGetter: () => _scale,
      ),
      TextElement() => TextNoteWidget(
        element: element,
        selected: selected,
        scaleGetter: () => _scale,
      ),
    };
  }
}
