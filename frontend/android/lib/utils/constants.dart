import 'dart:math' as dartmath;

import 'package:flutter_dotenv/flutter_dotenv.dart';

class AppConstants {
  static const String appName    = 'HiDocs!';
  static const String appVersion = '1.0.0';

  static String get appBaseUrl {
    final envUrl = dotenv.env['API_BASE_URL']?.trim();
    if (envUrl != null && envUrl.isNotEmpty) {
      return envUrl.endsWith('/')
          ? envUrl.substring(0, envUrl.length - 1)
          : envUrl;
    }
    return 'http://localhost:8080/api/v1';
  }
}

String generateRandomLink(int length) {
  const chars = 'abcdefghijklmnopqrstuvwxyz0123456789';
  final random = dartmath.Random.secure();
  return List.generate(length, (_) => chars[random.nextInt(chars.length)])
      .join();
}
