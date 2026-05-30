import 'package:flutter/foundation.dart';
import 'dart:io';

class ApiConstants {
  /// Production backend (Render).
  /// Override at build time:
  /// `flutter run --dart-define=API_BASE_URL=https://your-backend.onrender.com`
  static const String productionBaseUrl =
      'https://flutternewsapp-5vkz.onrender.com';

  static String get baseUrl {
    const override = String.fromEnvironment('API_BASE_URL');
    if (override.isNotEmpty) return override;

    if (kReleaseMode) return productionBaseUrl;

    if (!kIsWeb && Platform.isAndroid) {
      return 'http://10.0.2.2:8080';
    }
    return 'http://localhost:8080';
  }
}
