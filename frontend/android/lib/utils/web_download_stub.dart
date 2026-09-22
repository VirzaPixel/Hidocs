import 'dart:typed_data';

/// Versi non-web: tidak melakukan apa pun (dipakai lewat conditional import).
class WebDownload {
  static Future<void> save(
    Uint8List bytes,
    String fileName,
    String mimeType,
  ) async {}
}
