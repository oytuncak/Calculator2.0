import 'dart:convert';

import '../model/project.dart';

/// Reads/writes a [Project] as a `.calc2x` JSON document.
///
/// Only source-of-truth is stored (raw equation text, references as `@id`,
/// positions); results are recomputed on load so a file can never hold stale
/// values. [formatVersion] enables future migrations.
class DocumentCodec {
  static const int formatVersion = 1;

  String encode(Project project, {bool pretty = false}) {
    final map = {
      'formatVersion': formatVersion,
      'project': project.toJson(),
    };
    return pretty
        ? const JsonEncoder.withIndent('  ').convert(map)
        : jsonEncode(map);
  }

  Project decode(String source) {
    final map = jsonDecode(source) as Map<String, dynamic>;
    final version = map['formatVersion'] as int? ?? 1;
    if (version > formatVersion) {
      throw FormatException(
        'Unsupported document version $version (max $formatVersion)',
      );
    }
    return Project.fromJson(map['project'] as Map<String, dynamic>);
  }
}
