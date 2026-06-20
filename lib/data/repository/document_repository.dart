import 'package:shared_preferences/shared_preferences.dart';

import '../../domain/model/project.dart';
import '../../domain/serialization/document_codec.dart';

/// Persists the working document. Abstracted so M2 can swap in file-based
/// `.calc2x` storage / cloud sync without touching the controller.
abstract interface class DocumentRepository {
  Future<Project?> load();
  Future<void> save(Project project);
}

/// Cross-platform persistence (incl. web) backed by [SharedPreferences].
class SharedPrefsDocumentRepository implements DocumentRepository {
  SharedPrefsDocumentRepository(this._codec);

  static const _key = 'calc2x_document_v1';
  final DocumentCodec _codec;

  @override
  Future<Project?> load() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_key);
    if (raw == null || raw.isEmpty) return null;
    try {
      return _codec.decode(raw);
    } on FormatException {
      return null; // corrupt / incompatible: fall back to a fresh document
    }
  }

  @override
  Future<void> save(Project project) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_key, _codec.encode(project));
  }
}
