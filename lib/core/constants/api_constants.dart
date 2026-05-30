import 'package:flutter/foundation.dart';
import 'dart:io';

class ApiConstants {
  /// Production backend (Render).
  static const String productionBaseUrl =
      'https://flutternewsapp-5vkz.onrender.com';

  static String get baseUrl {
    const override = String.fromEnvironment('API_BASE_URL');
    if (override.isNotEmpty) return override;

    const useLocalBackend =
        bool.fromEnvironment('USE_LOCAL_BACKEND', defaultValue: false);
    if (useLocalBackend) {
      if (!kIsWeb && Platform.isAndroid) {
        return 'http://10.0.2.2:8080';
      }
      return 'http://localhost:8080';
    }

    return productionBaseUrl;
  }
}
