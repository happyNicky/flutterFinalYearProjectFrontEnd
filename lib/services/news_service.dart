import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import '../models/article_model.dart';
import '../core/constants/api_constants.dart';

final newsServiceProvider = Provider((ref) => NewsService());

class NewsService {
  String get _baseUrl => ApiConstants.baseUrl;

  Future<List<Article>> getTrending() async {
    final response = await http.get(Uri.parse('$_baseUrl/api/news/trending'));
    if (response.statusCode != 200) return [];
    return _parseArticleList(response.body);
  }

  Future<List<Article>> getByCategory(String category) async {
    final response = await http.get(
      Uri.parse(
        '$_baseUrl/api/news/category?name=${Uri.encodeComponent(category)}',
      ),
    );
    if (response.statusCode != 200) return [];
    return _parseArticleList(response.body);
  }

  Future<List<Article>> searchNews(String query) async {
    if (query.trim().isEmpty) return [];
    final response = await http.get(
      Uri.parse('$_baseUrl/api/news/search?q=${Uri.encodeComponent(query)}'),
    );
    if (response.statusCode != 200) return [];
    return _parseArticleList(response.body);
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
    return _parseArticleList(response.body);
  }

  // --- BOOKMARKS SYNC & STORAGE ---

  Future<List<Article>> getBookmarks(String token) async {
    final response = await http.get(
      Uri.parse('$_baseUrl/api/bookmarks'),
      headers: _authHeader(token),
    );
    if (response.statusCode != 200) return [];
    return _parseArticleList(response.body);
  }

  Future<bool> toggleBookmark(String token, Article article) async {
    final response = await http.post(
      Uri.parse('$_baseUrl/api/bookmarks/toggle'),
      headers: _authHeader(token),
      body: jsonEncode(article.toJson()),
    );
    if (response.statusCode != 200) return false;
    try {
      final data = jsonDecode(response.body) as Map<String, dynamic>;
      return data['bookmarked'] == true;
    } catch (_) {
      return false;
    }
  }

  Map<String, String> _authHeader(String? token) {
    final headers = {'Content-Type': 'application/json'};
    if (token != null && token.isNotEmpty) {
      headers['Authorization'] = 'Bearer $token';
    }
    return headers;
  }

  List<Article> _parseArticleList(String body) {
    final data = jsonDecode(body);
    if (data is! List) return [];
    return data
        .whereType<Map>()
        .map((item) => Map<String, dynamic>.from(item))
        .map(Article.fromJson)
        .toList();
  }

}
