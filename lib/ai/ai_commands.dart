import '../domain/model/element_id.dart';

/// The single mutation vocabulary for the document.
///
/// Every change to a canvas — whether triggered by the UI or, later, by an AI
/// assistant / MCP server — is expressed as one of these commands and applied
/// through the same pipeline. This guarantees the AI can only do what the user
/// can do, and that recompute happens identically for both.
sealed class DocumentCommand {
  const DocumentCommand();
}

class AddEquation extends DocumentCommand {
  const AddEquation({required this.x, required this.y, this.rawText = ''});
  final double x;
  final double y;
  final String rawText;
}

class AddText extends DocumentCommand {
  const AddText({required this.x, required this.y, this.text = ''});
  final double x;
  final double y;
  final String text;
}

class EditElement extends DocumentCommand {
  const EditElement(this.id, this.rawText);
  final ElementId id;
  final String rawText;
}

class MoveElement extends DocumentCommand {
  const MoveElement(this.id, this.x, this.y);
  final ElementId id;
  final double x;
  final double y;
}

/// Inserts a reference to [target]'s result into [source]'s text.
class LinkElements extends DocumentCommand {
  const LinkElements({required this.source, required this.target});
  final ElementId source;
  final ElementId target;
}

class DeleteElement extends DocumentCommand {
  const DeleteElement(this.id);
  final ElementId id;
}

class CreateCanvas extends DocumentCommand {
  const CreateCanvas(this.name);
  final String name;
}

class RenameCanvas extends DocumentCommand {
  const RenameCanvas(this.id, this.name);
  final ElementId id;
  final String name;
}

class DeleteCanvas extends DocumentCommand {
  const DeleteCanvas(this.id);
  final ElementId id;
}
