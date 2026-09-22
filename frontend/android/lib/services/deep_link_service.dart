import 'package:flutter/services.dart';

class DeepLinkService {
  DeepLinkService._();

  static const _channel = MethodChannel('hidocs/deep_link');

  static Future<String?> getInitialLink() async {
    try {
      final link = await _channel.invokeMethod<String>('getInitialLink');
      if (link == null || link.isEmpty) return null;
      return link;
    } catch (_) {
      return null;
    }
  }

  static String? extractSlug(String? link) {
    if (link == null || link.isEmpty) return null;
    final uri = Uri.tryParse(link.trim());
    if (uri == null) return null;
    final segs = uri.pathSegments.where((s) => s.isNotEmpty).toList();
    if (segs.length >= 2 && segs[segs.length - 2] == 'f') {
      return Uri.decodeComponent(segs.last);
    }
    if (segs.isNotEmpty) return Uri.decodeComponent(segs.last);
    return null;
  }

  static String? slugFromRoute(String? name) {
    if (name == null || name.isEmpty) return null;
    if (name.startsWith('/f/') && name.length > 3) {
      return Uri.decodeComponent(name.substring(3));
    }
    final uri = Uri.tryParse(name);
    if (uri != null && uri.hasAuthority) {
      final host = uri.host.toLowerCase();
      if (host == 'hidocs.app' ||
          host.endsWith('.hidocs.app') ||
          host == 'hidocs.my.id' ||
          host.endsWith('.hidocs.my.id')) {
        final segs =
            uri.pathSegments.where((s) => s.isNotEmpty).toList();
        if (segs.length >= 2 && segs[0] == 'f') {
          return Uri.decodeComponent(segs[1]);
        }
      }
    }
    return null;
  }
}
