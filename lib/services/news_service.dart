import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import '../models/article_model.dart';
import '../core/constants/api_constants.dart';

final newsServiceProvider = Provider((ref) => NewsService());

class BookmarkToggleResult {
  final bool success;
  final bool bookmarked;
  final String? errorMessage;

  const BookmarkToggleResult({
    required this.success,
    required this.bookmarked,
    this.errorMessage,
  });
}

List<Article> parseArticleList(String body) {
  final data = jsonDecode(body);
  List<dynamic> items;
  if (data is List) {
    items = data;
  } else if (data is Map && data['bookmarks'] is List) {
    items = data['bookmarks'] as List;
  } else {
    return [];
  }

  return items
      .whereType<Map>()
      .map((item) => Map<String, dynamic>.from(item))
      .map(Article.fromJson)
      .where((article) => article.id.trim().isNotEmpty)
      .toList();
}

class NewsService {
  String get _baseUrl => ApiConstants.baseUrl;

  Future<List<Article>> getTrending() async {
    final response = await http.get(Uri.parse('$_baseUrl/api/news/trending'));
    if (response.statusCode != 200) return [];
    return compute(parseArticleList, response.body);
  }

  Future<List<Article>> getByCategory(String category) async {
    final response = await http.get(
      Uri.parse(
        '$_baseUrl/api/news/category?name=${Uri.encodeComponent(category)}',
      ),
    );
    if (response.statusCode != 200) return [];
    return compute(parseArticleList, response.body);
  }

  Future<List<Article>> searchNews(String query) async {
    if (query.trim().isEmpty) return [];
    final response = await http.get(
      Uri.parse('$_baseUrl/api/news/search?q=${Uri.encodeComponent(query)}'),
    );
    if (response.statusCode != 200) return [];
    return compute(parseArticleList, response.body);
  }

  Future<List<Article>> getRecommended({
    String? token,
    double? latitude,
    double? longitude,
    int page = 1,
    int pageSize = 15,
    List<String> excludeIds = const [],
  }) async {
    final trimmedExclude = excludeIds.length > 200
        ? excludeIds.sublist(excludeIds.length - 200)
        : excludeIds;

    final response = await http.post(
      Uri.parse('$_baseUrl/api/news/recommended/feed'),
      headers: _authHeader(token),
      body: jsonEncode({
        'latitude': latitude,
        'longitude': longitude,
        'page': page,
        'pageSize': pageSize,
        'excludeIds': trimmedExclude,
      }),
    );
    if (response.statusCode != 200) return [];
    return compute(parseArticleList, response.body);
  }

  Future<List<Article>> getBookmarks(String token) async {
    final response = await http.get(
      Uri.parse('$_baseUrl/api/bookmarks'),
      headers: _authHeader(token),
    );
    if (response.statusCode == 401 ||
        response.statusCode == 302 ||
        response.statusCode == 301) {
      throw Exception('Session expired. Please log in again.');
    }
    if (response.statusCode != 200) {
      debugPrint('getBookmarks failed: ${response.statusCode} ${response.body}');
      throw Exception('Failed to load bookmarks (${response.statusCode}).');
    }
    return compute(parseArticleList, response.body);
  }

  Future<BookmarkToggleResult> toggleBookmark(String token, Article article) async {
    if (article.id.trim().isEmpty) {
      return const BookmarkToggleResult(
        success: false,
        bookmarked: false,
        errorMessage: 'This article cannot be bookmarked (missing id).',
      );
    }

    final response = await http.post(
      Uri.parse('$_baseUrl/api/bookmarks/toggle'),
      headers: _authHeader(token),
      body: jsonEncode(article.toBookmarkJson()),
    );

    if (response.statusCode == 401 ||
        response.statusCode == 302 ||
        response.statusCode == 301) {
      return const BookmarkToggleResult(
        success: false,
        bookmarked: false,
        errorMessage: 'Session expired. Please log in again.',
      );
    }

    if (response.statusCode != 200) {
      debugPrint('toggleBookmark failed: ${response.statusCode} ${response.body}');
      return BookmarkToggleResult(
        success: false,
        bookmarked: false,
        errorMessage: 'Bookmark failed (${response.statusCode}).',
      );
    }

    try {
      final data = jsonDecode(response.body) as Map<String, dynamic>;
      final raw = data['bookmarked'];
      final bookmarked = raw == true || raw == 'true';
      return BookmarkToggleResult(success: true, bookmarked: bookmarked);
    } catch (e) {
      debugPrint('toggleBookmark parse error: $e');
      return const BookmarkToggleResult(
        success: false,
        bookmarked: false,
        errorMessage: 'Invalid bookmark response from server.',
      );
    }
  }

  Map<String, String> _authHeader(String? token) {
    final headers = {'Content-Type': 'application/json'};
    if (token != null && token.isNotEmpty) {
      headers['Authorization'] = 'Bearer $token';
    }
    return headers;
  }
}
