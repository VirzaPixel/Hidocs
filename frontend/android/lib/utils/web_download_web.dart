import 'dart:js_interop';
import 'dart:typed_data';

import 'package:web/web.dart' as web;

/// Versi web: memicu unduhan berkas di browser.
class WebDownload {
  static Future<void> save(
    Uint8List bytes,
    String fileName,
    String mimeType,
  ) async {
    final blob = web.Blob(
      [bytes.toJS].toJS,
      web.BlobPropertyBag(type: mimeType),
    );
    final url = web.URL.createObjectURL(blob);
    final anchor = web.HTMLAnchorElement()
      ..href = url
      ..download = fileName;
    anchor.click();
    web.URL.revokeObjectURL(url);
  }
}
