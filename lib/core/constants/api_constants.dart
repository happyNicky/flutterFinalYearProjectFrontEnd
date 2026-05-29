import 'package:flutter/foundation.dart';
import 'dart:io';

class ApiConstants {
  /// Set after Railway deploy: Settings → Networking → Generate Domain.
  /// Override at build time:
  /// `flutter run --dart-define=API_BASE_URL=https://your-app.up.railway.app`
  static const String railwayBaseUrl =
      'https://flutternewsapp-production.up.railway.app';

  static String get baseUrl {
    const override = String.fromEnvironment('API_BASE_URL');
    if (override.isNotEmpty) return override;

    if (kReleaseMode) return railwayBaseUrl;

    if (!kIsWeb && Platform.isAndroid) {
      return 'http://10.0.2.2:8080';
    }
    return 'http://localhost:8080';
  }
}
