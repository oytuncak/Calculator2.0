import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../ai/ai_commands.dart';
import '../../../domain/model/element.dart';
import '../../../state/document_controller.dart';

/// A free text note / title / label on the canvas.
class TextNoteWidget extends ConsumerStatefulWidget {
  const TextNoteWidget({
    super.key,
    required this.element,
    required this.selected,
    required this.scaleGetter,
  });

  final TextElement element;
  final bool selected;
  final double Function() scaleGetter;

  @override
  ConsumerState<TextNoteWidget> createState() => _TextNoteWidgetState();
}

class _TextNoteWidgetState extends ConsumerState<TextNoteWidget> {
  late final TextEditingController _text = TextEditingController(
    text: widget.element.text,
  );
  final _focus = FocusNode();

  @override
  void didUpdateWidget(TextNoteWidget old) {
    super.didUpdateWidget(old);
    if (widget.element.text != _text.text && !_focus.hasFocus) {
      _text.text = widget.element.text;
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
    return SizedBox(
      width: widget.element.width,
      child: GestureDetector(
        onTap: () => _controller.select(widget.element.id),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: widget.selected ? scheme.primary : Colors.transparent,
              width: 2,
            ),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              GestureDetector(
                behavior: HitTestBehavior.opaque,
                onPanUpdate: (d) {
                  final s = widget.scaleGetter();
                  _controller.apply(
                    MoveElement(
                      widget.element.id,
                      widget.element.x + d.delta.dx / s,
                      widget.element.y + d.delta.dy / s,
                    ),
                  );
                },
                child: Padding(
                  padding: const EdgeInsets.only(top: 10, right: 4),
                  child: Icon(
                    Icons.drag_indicator,
                    size: 16,
                    color: scheme.onSurfaceVariant,
                  ),
                ),
              ),
              Expanded(
                child: TextField(
                  controller: _text,
                  focusNode: _focus,
                  maxLines: null,
                  style: TextStyle(
                    fontSize: widget.element.fontSize,
                    fontWeight: widget.element.bold
                        ? FontWeight.bold
                        : FontWeight.normal,
                  ),
                  decoration: const InputDecoration(hintText: 'note…'),
                  onChanged: (t) =>
                      _controller.apply(EditElement(widget.element.id, t)),
                ),
              ),
              InkWell(
                onTap: () =>
                    _controller.apply(DeleteElement(widget.element.id)),
                child: Icon(
                  Icons.close,
                  size: 14,
                  color: scheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
