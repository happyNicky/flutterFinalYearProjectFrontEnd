import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../../../core/constants/api_constants.dart';
import '../../../core/services/notification_service.dart';
import '../../../models/article_model.dart';
import '../../auth/providers/auth_provider.dart';

class NotificationPayload {
  final String id;
  final String title;
  final String message;
  final DateTime timestamp;
  final String? articleId;
  final Map<String, dynamic>? articleData;

  NotificationPayload({
    required this.id,
    required this.title,
    required this.message,
    required this.timestamp,
    this.articleId,
    this.articleData,
  });

  Article? toArticle() {
    if (articleData != null) {
      try {
        return Article.fromJson(articleData!);
      } catch (_) {
        return null;
      }
    }
    return null;
  }

  bool get isArticleNotification => articleId != null && articleId!.isNotEmpty;

  bool get isSystemMessage {
    if (isArticleNotification) return false;
    return title == 'Connected' ||
        title == 'Disconnected' ||
        title.startsWith('Connection Error');
  }

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
      id:
          (json['id'] as String?) ??
          '${dt.millisecondsSinceEpoch}_${json['title'] ?? ''}_${json['message'] ?? ''}',
      title: json['title'] ?? '',
      message: json['message'] ?? '',
      timestamp: dt,
      articleId: json['articleId'] as String?,
      articleData: json['articleData'] is Map<String, dynamic>
          ? json['articleData'] as Map<String, dynamic>
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'message': message,
      'timestamp': timestamp.millisecondsSinceEpoch,
      if (articleId != null) 'articleId': articleId,
      if (articleData != null) 'articleData': articleData,
    };
  }
}

final notificationBadgeCountProvider = Provider<int>((ref) {
  final notifications = ref.watch(notificationHistoryProvider);
  return notifications.where((n) => n.isArticleNotification).length;
});

final notificationStreamProvider = StreamProvider<NotificationPayload>((ref) {
  final controller = StreamController<NotificationPayload>();
  final token = ref.watch(authProvider).token;

  if (token == null || token.isEmpty) {
    controller.add(
      NotificationPayload(
        id: 'disconnected_${DateTime.now().millisecondsSinceEpoch}',
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
      id: 'connected_${DateTime.now().millisecondsSinceEpoch}',
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
          id: 'conn_err_${DateTime.now().millisecondsSinceEpoch}',
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
                  if (eventName == 'notification' && payload.isArticleNotification) {
                    NotificationService().showBreakingNewsNotification(
                      payload.title,
                      payload.message,
                    );
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
                  id: 'conn_err_${DateTime.now().millisecondsSinceEpoch}',
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
          id: 'conn_err_${DateTime.now().millisecondsSinceEpoch}',
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
  static const _storageKey = 'notification_history_v1';
  static const _notifiedArticlesKey = 'notified_article_ids_v1';
  StreamSubscription<NotificationPayload>? _streamSubscription;
  Set<String> _notifiedArticleIds = {};

  NotificationHistoryNotifier(Stream<NotificationPayload> stream) : super([]) {
    _init(stream);
  }

  Future<void> _init(Stream<NotificationPayload> stream) async {
    await _loadNotifiedArticleIds();
    await _loadFromStorage();
    _streamSubscription = stream.listen((payload) {
      if (payload.isSystemMessage) return;
      if (payload.isArticleNotification &&
          state.any((n) => n.articleId == payload.articleId)) {
        return;
      }
      state = [payload, ...state];
      _saveToStorage();
    });
  }

  void notifyUnreadRecommended(List<Article> recommended, Set<String> readIds) {
    final pending = recommended
        .where((article) => !readIds.contains(article.id))
        .where((article) => !_notifiedArticleIds.contains(article.id))
        .where((article) => !state.any((n) => n.articleId == article.id))
        .take(2)
        .toList();

    if (pending.isEmpty) return;

    final additions = <NotificationPayload>[];
    for (final article in pending) {
      final preview = article.content.length > 140
          ? '${article.content.substring(0, 140)}...'
          : article.content;

      additions.add(
        NotificationPayload(
          id: 'article_${article.id}',
          articleId: article.id,
          articleData: article.toJson(),
          title: article.title,
          message: preview.isEmpty ? 'Tap to read this recommended story.' : preview,
          timestamp: DateTime.now(),
        ),
      );
      _notifiedArticleIds.add(article.id);
    }

    state = [...additions, ...state];
    _saveToStorage();
    _saveNotifiedArticleIds();

    for (final notification in additions) {
      NotificationService().showBreakingNewsNotification(
        notification.title,
        notification.message,
      );
    }
  }

  void clearHistory() {
    state = [];
    _saveToStorage();
  }

  void markAsRead(String id) {
    state = state.where((notification) => notification.id != id).toList();
    _saveToStorage();
  }

  void deleteNotification(String id) {
    state = state.where((notification) => notification.id != id).toList();
    _saveToStorage();
  }

  void clearForArticle(String articleId) {
    state = state.where((notification) => notification.articleId != articleId).toList();
    _saveToStorage();
  }

  Future<void> _loadFromStorage() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_storageKey);
    if (raw == null || raw.isEmpty) return;

    try {
      final decoded = jsonDecode(raw);
      if (decoded is! List) return;
      state = decoded
          .whereType<Map<String, dynamic>>()
          .map(NotificationPayload.fromJson)
          .where((n) => !n.isSystemMessage)
          .toList();
    } catch (_) {
      // Ignore invalid payload and keep current state.
    }
  }

  Future<void> _saveToStorage() async {
    final prefs = await SharedPreferences.getInstance();
    final encoded = jsonEncode(state.map((e) => e.toJson()).toList());
    await prefs.setString(_storageKey, encoded);
  }

  Future<void> _loadNotifiedArticleIds() async {
    final prefs = await SharedPreferences.getInstance();
    _notifiedArticleIds =
        (prefs.getStringList(_notifiedArticlesKey) ?? []).toSet();
  }

  Future<void> _saveNotifiedArticleIds() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(
      _notifiedArticlesKey,
      _notifiedArticleIds.toList(),
    );
  }

  @override
  void dispose() {
    _streamSubscription?.cancel();
    super.dispose();
  }
}

final notificationHistoryProvider =
    StateNotifierProvider<
      NotificationHistoryNotifier,
      List<NotificationPayload>
    >((ref) {
      ref.keepAlive();
      final stream = ref.watch(notificationStreamProvider.stream);
      return NotificationHistoryNotifier(stream);
    });
