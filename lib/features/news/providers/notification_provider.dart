import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import '../../../core/constants/api_constants.dart';
import '../../auth/providers/auth_provider.dart';

class NotificationPayload {
  final String title;
  final String message;
  final DateTime timestamp;

  NotificationPayload({
    required this.title,
    required this.message,
    required this.timestamp,
  });

  factory NotificationPayload.fromJson(Map<String, dynamic> json) {
    dynamic ts = json['timestamp'];
    DateTime dt;
    if (ts is String) {
      dt = DateTime.fromMillisecondsSinceEpoch(
        int.tryParse(ts) ?? DateTime.now().millisecondsSinceEpoch,
      );
    } else if (ts is num) {
      dt = DateTime.fromMillisecondsSinceEpoch(ts.toInt());
    } else {
      dt = DateTime.now();
    }

    return NotificationPayload(
      title: json['title'] ?? '',
      message: json['message'] ?? '',
      timestamp: dt,
    );
  }
}

final notificationStreamProvider = StreamProvider<NotificationPayload>((ref) {
  final controller = StreamController<NotificationPayload>();
  final token = ref.watch(authProvider).token;

  if (token == null || token.isEmpty) {
    controller.add(
      NotificationPayload(
        title: "Disconnected",
        message: "Log in to receive real-time news alerts.",
        timestamp: DateTime.now(),
      ),
    );
    ref.onDispose(() => controller.close());
    return controller.stream;
  }

  controller.add(
    NotificationPayload(
      title: "Connected",
      message: "You are now connected to Spring real-time news alerts!",
      timestamp: DateTime.now(),
    ),
  );

  final client = http.Client();
  final request = http.Request(
    'GET',
    Uri.parse('${ApiConstants.baseUrl}/api/notifications/stream'),
  );
  request.headers['Authorization'] = 'Bearer $token';
  request.headers['Accept'] = 'text/event-stream';

  StreamSubscription<String>? linesSubscription;

  client.send(request).then((response) {
    if (response.statusCode != 200) {
      controller.add(
        NotificationPayload(
          title: "Connection Error",
          message: "Notification stream failed: ${response.statusCode}",
          timestamp: DateTime.now(),
        ),
      );
      return;
    }

    String? eventName;
    final dataLines = <String>[];

    linesSubscription = response.stream
        .transform(utf8.decoder)
        .transform(const LineSplitter())
        .listen(
          (line) {
            if (line.startsWith('event:')) {
              eventName = line.substring(6).trim();
              return;
            }
            if (line.startsWith('data:')) {
              dataLines.add(line.substring(5).trim());
              return;
            }
            if (line.isEmpty && dataLines.isNotEmpty) {
              final rawData = dataLines.join('\n');
              dataLines.clear();
              try {
                final decoded = jsonDecode(rawData);
                if (decoded is Map<String, dynamic>) {
                  final payload = NotificationPayload.fromJson(decoded);
                  controller.add(payload);
                  if (eventName == 'notification') {
                    // NotificationService().showBreakingNewsNotification(
                    //   payload.title,
                    //   payload.message,
                    // );
                  }
                }
              } catch (e) {
                debugPrint('SSE parse error: $e');
              } finally {
                eventName = null;
              }
            }
          },
          onError: (e) {
            if (!controller.isClosed) {
              controller.add(
                NotificationPayload(
                  title: "Connection Error",
                  message: "Notification stream error.",
                  timestamp: DateTime.now(),
                ),
              );
            }
          },
        );
  }).catchError((_) {
    if (!controller.isClosed) {
      controller.add(
        NotificationPayload(
          title: "Connection Error",
          message: "Could not connect to Spring notification stream.",
          timestamp: DateTime.now(),
        ),
      );
    }
  });

  ref.onDispose(() async {
    await linesSubscription?.cancel();
    client.close();
    await controller.close();
  });

  return controller.stream;
});

class NotificationHistoryNotifier
    extends StateNotifier<List<NotificationPayload>> {
  NotificationHistoryNotifier(Stream<NotificationPayload> stream) : super([]) {
    stream.listen((payload) {
      // Don't show Connected handshake in full notifications screen lists
      if (payload.title == "Connected") return;
      state = [payload, ...state];
    });
  }

  void clearHistory() {
    state = [];
  }
}

final notificationHistoryProvider =
    StateNotifierProvider<
      NotificationHistoryNotifier,
      List<NotificationPayload>
    >((ref) {
      final stream = ref.watch(notificationStreamProvider.stream);
      return NotificationHistoryNotifier(stream);
    });
