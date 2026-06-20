import 'dart:convert';

import '../model/workspace.dart';

/// Reads/writes a whole [Workspace] (all projects + the open project/canvas)
/// as JSON. Builds on the per-element source-of-truth model, so results are
/// always recomputed on load.
class WorkspaceCodec {
  static const int formatVersion = 2;

  String encode(Workspace workspace, {bool pretty = false}) {
    final map = {
      'formatVersion': formatVersion,
      'workspace': workspace.toJson(),
    };
    return pretty
        ? const JsonEncoder.withIndent('  ').convert(map)
        : jsonEncode(map);
  }

  Workspace decode(String source) {
    final map = jsonDecode(source) as Map<String, dynamic>;
    final version = map['formatVersion'] as int? ?? formatVersion;
    if (version > formatVersion) {
      throw FormatException(
        'Unsupported workspace version $version (max $formatVersion)',
      );
    }
    return Workspace.fromJson(map['workspace'] as Map<String, dynamic>);
  }
}
