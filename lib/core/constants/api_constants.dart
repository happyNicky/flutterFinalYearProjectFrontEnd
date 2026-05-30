import 'package:flutter/foundation.dart';
import 'dart:io';

class ApiConstants {
  static String get baseUrl {
    if (!kIsWeb && Platform.isAndroid) {
      return 'http://10.0.2.2:8080';
    }
    return 'http://localhost:8080';
  }
}
