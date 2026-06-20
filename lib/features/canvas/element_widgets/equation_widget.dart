import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../ai/ai_commands.dart';
import '../../../domain/engine/number_format.dart';
import '../../../domain/model/cell_value.dart';
import '../../../domain/model/element.dart';
import '../../../domain/model/element_id.dart';
import '../../../state/document_controller.dart';

/// A single equation on the canvas: an editable input, a live result, and a
/// draggable result pill used to link this value into other equations.
class EquationWidget extends ConsumerStatefulWidget {
  const EquationWidget({
    super.key,
    required this.element,
    required this.value,
    required this.selected,
    required this.scaleGetter,
  });

  final EquationElement element;
  final CellValue value;
  final bool selected;

  /// Returns the current canvas scale, so move-drags convert screen → canvas.
  final double Function() scaleGetter;

  @override
  ConsumerState<EquationWidget> createState() => _EquationWidgetState();
}

class _EquationWidgetState extends ConsumerState<EquationWidget> {
  late final TextEditingController _text =
      TextEditingController(text: widget.element.rawText);
  final _focus = FocusNode();

  @override
  void didUpdateWidget(EquationWidget old) {
    super.didUpdateWidget(old);
    // External changes (e.g. a link inserted via drag) must reflect in the
    // field without clobbering the caret while the user is actively typing.
    if (widget.element.rawText != _text.text && !_focus.hasFocus) {
      _text.text = widget.element.rawText;
    }
  }

  @override
  void dispose() {
    _text.dispose();
    _focus.dispose();
    super.dispose();
  }

  DocumentController get _controller =>
      ref.read(documentControllerProvider.notifier);

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return DragTarget<ElementRef>(
      onWillAcceptWithDetails: (d) => d.data.id != widget.element.id,
      onAcceptWithDetails: (d) => _controller.apply(
        LinkElements(source: widget.element.id, target: d.data.id),
      ),
      builder: (context, candidate, _) {
        final highlight = candidate.isNotEmpty;
        return SizedBox(
          width: widget.element.width,
          child: GestureDetector(
            onTap: () => _controller.select(widget.element.id),
            child: Card(
              color: highlight ? scheme.primaryContainer : null,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
                side: BorderSide(
                  color: widget.selected ? scheme.primary : Colors.transparent,
                  width: 2,
                ),
              ),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(8, 4, 8, 8),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _header(scheme),
                    TextField(
                      controller: _text,
                      focusNode: _focus,
                      style: const TextStyle(
                          fontFamily: 'monospace', fontSize: 16),
                      decoration: const InputDecoration(
                        hintText: 'type an expression…',
                        contentPadding: EdgeInsets.symmetric(vertical: 4),
                      ),
                      onChanged: (t) => _controller
                          .apply(EditElement(widget.element.id, t)),
                    ),
                    const SizedBox(height: 6),
                    _resultRow(scheme),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _header(ColorScheme scheme) {
    return Row(
      children: [
        // Drag handle: moving the element (vs. panning the canvas).
        GestureDetector(
          behavior: HitTestBehavior.opaque,
          onPanUpdate: (d) {
            final s = widget.scaleGetter();
            _controller.apply(MoveElement(
              widget.element.id,
              widget.element.x + d.delta.dx / s,
              widget.element.y + d.delta.dy / s,
            ));
          },
          child: Icon(Icons.drag_indicator,
              size: 18, color: scheme.onSurfaceVariant),
        ),
        const Spacer(),
        InkWell(
          onTap: () =>
              _controller.apply(DeleteElement(widget.element.id)),
          child: Icon(Icons.close, size: 16, color: scheme.onSurfaceVariant),
        ),
      ],
    );
  }

  Widget _resultRow(ColorScheme scheme) {
    final text = formatCellValue(widget.value);
    final isError = widget.value is ErrorValue;
    final pill = Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: isError
            ? scheme.errorContainer
            : scheme.secondaryContainer,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(
        text.isEmpty ? '—' : text,
        style: TextStyle(
          fontFamily: 'monospace',
          fontWeight: FontWeight.w600,
          color: isError ? scheme.onErrorContainer : scheme.onSecondaryContainer,
        ),
      ),
    );

    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        Text('= ', style: TextStyle(color: scheme.onSurfaceVariant)),
        // Drag the result into another equation to link it.
        Draggable<ElementRef>(
          data: ElementRef(widget.element.id),
          feedback: Material(color: Colors.transparent, child: pill),
          childWhenDragging: Opacity(opacity: 0.4, child: pill),
          child: Tooltip(
            message: 'Drag onto another equation to link',
            child: pill,
          ),
        ),
      ],
    );
  }
}

/// Drag payload carrying the id of the equation whose result is being linked.
class ElementRef {
  const ElementRef(this.id);
  final ElementId id;
}
