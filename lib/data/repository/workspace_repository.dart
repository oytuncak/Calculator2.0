import 'package:shared_preferences/shared_preferences.dart';

import '../../domain/model/workspace.dart';
import '../../domain/serialization/workspace_codec.dart';

/// Persists the whole workspace. Abstracted so a later milestone can swap in
/// file-based `.calc2x` storage / cloud sync without touching the controller.
abstract interface class WorkspaceRepository {
  Future<Workspace?> load();
  Future<void> save(Workspace workspace);
}

/// Cross-platform persistence (incl. web) backed by [SharedPreferences].
class SharedPrefsWorkspaceRepository implements WorkspaceRepository {
  SharedPrefsWorkspaceRepository(this._codec);

  static const _key = 'calc2x_workspace_v1';
  final WorkspaceCodec _codec;

  @override
  Future<Workspace?> load() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_key);
    if (raw == null || raw.isEmpty) return null;
    try {
      return _codec.decode(raw);
    } on FormatException {
      return null;
    }
  }

  @override
  Future<void> save(Workspace workspace) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_key, _codec.encode(workspace));
  }
}
