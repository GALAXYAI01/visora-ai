import 'dart:js_interop';
import 'dart:convert';
import 'package:web/web.dart' as web;

/// Web-only file download helper.
/// Triggers a file save dialog in the browser.
class WebDownloader {
  static void downloadText(String content, String filename) {
    final bytes = utf8.encode(content);
    final jsArray = bytes.toJS;
    final blob = web.Blob([jsArray].toJS);
    final url = web.URL.createObjectURL(blob);
    final anchor = web.HTMLAnchorElement()
      ..href = url
      ..download = filename
      ..style.display = 'none';
    web.document.body!.appendChild(anchor);
    anchor.click();
    anchor.remove();
    web.URL.revokeObjectURL(url);
  }
}
