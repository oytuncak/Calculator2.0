import 'dart:typed_data';

import 'package:file_saver/file_saver.dart';

/// Saves exported bytes to the device / triggers a browser download on web.
/// Kept thin and separate from [XlsxExporter] so the byte-generation logic
/// stays pure and unit-testable.
class FileExportService {
  Future<void> saveXlsx(String fileName, List<int> bytes) async {
    await FileSaver.instance.saveFile(
      name: fileName,
      bytes: Uint8List.fromList(bytes),
      ext: 'xlsx',
      mimeType: MimeType.microsoftExcel,
    );
  }
}
