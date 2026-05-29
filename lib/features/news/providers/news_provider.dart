import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_news_app/models/article_model.dart';
import 'package:flutter_news_app/services/news_service.dart';
import 'package:flutter_news_app/features/auth/providers/auth_provider.dart';
import 'package:flutter_news_app/core/localization/language_provider.dart';
import 'package:flutter_news_app/features/news/providers/location_provider.dart';
import 'package:flutter_news_app/features/news/providers/notification_provider.dart';
import 'package:flutter_news_app/features/news/providers/read_articles_provider.dart';
import 'package:flutter_news_app/services/translation_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

const _trendingCacheKey = 'trending_articles_cache_v1';
const _recommendedCacheKey = 'recommended_articles_cache_v1';

Future<void> _saveArticlesCache(String key, List<Article> articles) async {
  final prefs = await SharedPreferences.getInstance();
  final encoded = jsonEncode(articles.map((a) => a.toJson()).toList());
  await prefs.setString(key, encoded);
}

Future<List<Article>> _loadArticlesCache(String key) async {
  final prefs = await SharedPreferences.getInstance();
  final raw = prefs.getString(key);
  if (raw == null || raw.isEmpty) return [];

  try {
    final decoded = jsonDecode(raw);
    if (decoded is! List) return [];
    return decoded
        .whereType<Map>()
        .map((item) => Map<String, dynamic>.from(item))
        .map(Article.fromJson)
        .toList();
  } catch (_) {
    return [];
  }
}

class TrendingNewsState {
  final List<Article> articles;
  final bool isLoading;
  final bool isRefreshing;
  final String? error;
  final bool hasLoaded;

  const TrendingNewsState({
    this.articles = const [],
    this.isLoading = false,
    this.isRefreshing = false,
    this.error,
    this.hasLoaded = false,
  });

  TrendingNewsState copyWith({
    List<Article>? articles,
    bool? isLoading,
    bool? isRefreshing,
    String? error,
    bool? hasLoaded,
  }) {
    return TrendingNewsState(
      articles: articles ?? this.articles,
      isLoading: isLoading ?? this.isLoading,
      isRefreshing: isRefreshing ?? this.isRefreshing,
      error: error,
      hasLoaded: hasLoaded ?? this.hasLoaded,
    );
  }
}

class TrendingNewsNotifier extends StateNotifier<TrendingNewsState> {
  final Ref ref;

  TrendingNewsNotifier(this.ref) : super(const TrendingNewsState()) {
    _init();
  }

  Future<void> _init() async {
    final cached = await _loadArticlesCache(_trendingCacheKey);
    if (cached.isNotEmpty) {
      state = TrendingNewsState(articles: cached, hasLoaded: true);
      await syncNewOnResume();
    } else {
      await refresh();
    }
  }

  Future<void> refresh() async {
    state = state.copyWith(isLoading: true, isRefreshing: false, error: null);
    await _fetchAndReplace();
  }

  Future<void> syncNewOnResume() async {
    if (state.isLoading || state.isRefreshing) return;

    final hasCache = state.articles.isNotEmpty;
    state = state.copyWith(isRefreshing: hasCache, isLoading: !hasCache);

    try {
      final service = ref.read(newsServiceProvider);
      final fetched = await service.getTrending();

      if (state.articles.isEmpty) {
        state = TrendingNewsState(
          articles: fetched,
          hasLoaded: true,
          isLoading: false,
          isRefreshing: false,
        );
      } else {
        final existingIds = state.articles.map((e) => e.id).toSet();
        final fresh = fetched.where((a) => !existingIds.contains(a.id)).toList();
        state = TrendingNewsState(
          articles: fresh.isEmpty ? state.articles : [...fresh, ...state.articles],
          hasLoaded: true,
          isLoading: false,
          isRefreshing: false,
        );
      }

      await _saveArticlesCache(_trendingCacheKey, state.articles);
    } catch (_) {
      state = state.copyWith(
        isLoading: false,
        isRefreshing: false,
        error: state.articles.isEmpty ? 'Failed to fetch trending news.' : null,
        hasLoaded: state.articles.isNotEmpty,
      );
    }
  }

  Future<void> _fetchAndReplace() async {
    try {
      final service = ref.read(newsServiceProvider);
      final fetched = await service.getTrending();
      state = TrendingNewsState(
        articles: fetched,
        hasLoaded: true,
        isLoading: false,
        isRefreshing: false,
      );
      await _saveArticlesCache(_trendingCacheKey, fetched);
    } catch (_) {
      state = state.copyWith(
        isLoading: false,
        isRefreshing: false,
        error: 'Failed to fetch trending news.',
        hasLoaded: state.articles.isNotEmpty,
      );
    }
  }
}

final trendingNewsProvider =
    StateNotifierProvider<TrendingNewsNotifier, TrendingNewsState>((ref) {
      ref.keepAlive();
      return TrendingNewsNotifier(ref);
    });

class RecommendedFeedState {
  final List<Article> articles;
  final bool isLoading;
  final bool isRefreshing;
  final bool hasMore;
  final int page;
  final String? error;
  final bool hasLoaded;

  const RecommendedFeedState({
    this.articles = const [],
    this.isLoading = false,
    this.isRefreshing = false,
    this.hasMore = true,
    this.page = 1,
    this.error,
    this.hasLoaded = false,
  });

  RecommendedFeedState copyWith({
    List<Article>? articles,
    bool? isLoading,
    bool? isRefreshing,
    bool? hasMore,
    int? page,
    String? error,
    bool? hasLoaded,
  }) {
    return RecommendedFeedState(
      articles: articles ?? this.articles,
      isLoading: isLoading ?? this.isLoading,
      isRefreshing: isRefreshing ?? this.isRefreshing,
      hasMore: hasMore ?? this.hasMore,
      page: page ?? this.page,
      error: error,
      hasLoaded: hasLoaded ?? this.hasLoaded,
    );
  }
}

class RecommendedFeedNotifier extends StateNotifier<RecommendedFeedState> {
  final Ref ref;

  RecommendedFeedNotifier(this.ref) : super(const RecommendedFeedState()) {
    _init();
  }

  Future<void> _init() async {
    final cached = await _loadArticlesCache(_recommendedCacheKey);
    if (cached.isNotEmpty) {
      state = RecommendedFeedState(
        articles: cached,
        page: 2,
        hasMore: true,
        hasLoaded: true,
      );
      await syncNewOnResume();
    } else {
      await refresh();
    }
  }

  Future<void> refresh() async {
    state = const RecommendedFeedState(isLoading: true, hasMore: true, page: 1);
    await _loadPage(reset: true);
  }

  Future<void> syncNewOnResume() async {
    if (state.isLoading || state.isRefreshing) return;

    final hasCache = state.articles.isNotEmpty;
    state = state.copyWith(
      isRefreshing: hasCache,
      isLoading: !hasCache,
      error: null,
    );

    try {
      final service = ref.read(newsServiceProvider);
      final auth = ref.read(authProvider);
      final location = ref.read(locationProvider);
      final excludeIds = state.articles.map((e) => e.id).toList();

      final fetched = await service.getRecommended(
        token: auth.token,
        latitude: location.hasConsent ? location.latitude : null,
        longitude: location.hasConsent ? location.longitude : null,
        page: 1,
        pageSize: 15,
        excludeIds: excludeIds,
      );

      if (state.articles.isEmpty) {
        state = RecommendedFeedState(
          articles: fetched,
          isLoading: false,
          isRefreshing: false,
          hasMore: fetched.length >= 15,
          page: 2,
          hasLoaded: true,
        );
      } else {
        final existingIds = state.articles.map((e) => e.id).toSet();
        final fresh = fetched.where((a) => !existingIds.contains(a.id)).toList();
        state = state.copyWith(
          articles: fresh.isEmpty ? state.articles : [...fresh, ...state.articles],
          isLoading: false,
          isRefreshing: false,
          hasLoaded: true,
        );
      }

      await _persistRecommended();
      _notifyUnreadRecommended();
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        isRefreshing: false,
        error: state.articles.isEmpty ? 'Failed to fetch recommended news.' : null,
        hasLoaded: state.articles.isNotEmpty,
      );
    }
  }

  Future<void> loadMore() async {
    if (state.isLoading || state.isRefreshing || !state.hasMore) return;
    state = state.copyWith(isLoading: true, error: null);
    await _loadPage(reset: false);
  }

  Future<void> _loadPage({required bool reset}) async {
    try {
      final service = ref.read(newsServiceProvider);
      final auth = ref.read(authProvider);
      final location = ref.read(locationProvider);
      final seen = (reset ? <String>{} : state.articles.map((e) => e.id).toSet()).toList();

      final fetched = await service.getRecommended(
        token: auth.token,
        latitude: location.hasConsent ? location.latitude : null,
        longitude: location.hasConsent ? location.longitude : null,
        page: reset ? 1 : state.page,
        pageSize: 15,
        excludeIds: seen,
      );

      final merged = reset ? fetched : [...state.articles, ...fetched];

      state = state.copyWith(
        articles: merged,
        isLoading: false,
        isRefreshing: false,
        hasMore: fetched.length >= 15,
        page: (reset ? 2 : state.page + 1),
        error: null,
        hasLoaded: true,
      );

      await _persistRecommended();
      _notifyUnreadRecommended();
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        isRefreshing: false,
        error: 'Failed to fetch recommended news.',
        hasLoaded: state.articles.isNotEmpty,
      );
    }
  }

  Future<void> _persistRecommended() async {
    await _saveArticlesCache(_recommendedCacheKey, state.articles);
  }

  void _notifyUnreadRecommended() {
    if (state.articles.isEmpty) return;
    final readIds = ref.read(readArticlesProvider);
    ref
        .read(notificationHistoryProvider.notifier)
        .notifyUnreadRecommended(state.articles, readIds);
  }
}

final recommendedFeedProvider =
    StateNotifierProvider<RecommendedFeedNotifier, RecommendedFeedState>((ref) {
      ref.keepAlive();
      return RecommendedFeedNotifier(ref);
    });

final recommendedNewsProvider = FutureProvider<List<Article>>((ref) async {
  final feed = ref.watch(recommendedFeedProvider);
  return feed.articles;
});

final categoryNewsProvider = FutureProvider.family<List<Article>, String>((
  ref,
  category,
) async {
  final service = ref.read(newsServiceProvider);
  final lang = ref.watch(languageProvider);
  final articles = await service.getByCategory(category);

  if (lang == 'am') {
    return TranslationService().translateArticles(articles);
  }
  return articles;
});

final searchNewsProvider = FutureProvider.family<List<Article>, String>((
  ref,
  query,
) async {
  if (query.trim().isEmpty) return [];
  final service = ref.read(newsServiceProvider);
  final lang = ref.watch(languageProvider);
  final articles = await service.searchNews(query);

  if (lang == 'am') {
    return TranslationService().translateArticles(articles);
  }
  return articles;
});

class BookmarksNotifier extends StateNotifier<AsyncValue<List<Article>>> {
  static const _localBookmarksKey = 'local_bookmarks_v1';
  final Ref ref;

  BookmarksNotifier(this.ref) : super(const AsyncValue.loading()) {
    _init();

    ref.listen(authProvider, (previous, next) {
      if (next.token != null) {
        fetchBookmarks();
      } else {
        _loadLocalBookmarks();
      }
    });

  }

  Future<void> _init() async {
    await _loadLocalBookmarks();
    if (ref.read(authProvider).token != null) {
      await fetchBookmarks();
    }
  }

  Future<void> _loadLocalBookmarks() async {
    final local = await _readLocalBookmarks();
    state = AsyncValue.data(local);
  }

  Future<List<Article>> _readLocalBookmarks() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_localBookmarksKey);
    if (raw == null || raw.isEmpty) return [];

    try {
      final decoded = jsonDecode(raw);
      if (decoded is! List) return [];
      return decoded
          .whereType<Map>()
          .map((item) => Map<String, dynamic>.from(item))
          .map(Article.fromJson)
          .where((article) => article.id.trim().isNotEmpty)
          .toList();
    } catch (_) {
      return [];
    }
  }

  Future<void> _saveLocalBookmarks(List<Article> bookmarks) async {
    final prefs = await SharedPreferences.getInstance();
    final encoded = jsonEncode(bookmarks.map((a) => a.toJson()).toList());
    await prefs.setString(_localBookmarksKey, encoded);
  }

  List<Article> _mergeBookmarks(List<Article> local, List<Article> server) {
    final merged = <String, Article>{};
    for (final article in server) {
      merged[article.id] = article;
    }
    for (final article in local) {
      merged.putIfAbsent(article.id, () => article);
    }
    return merged.values.toList();
  }

  Future<void> fetchBookmarks() async {
    final local = await _readLocalBookmarks();
    final token = ref.read(authProvider).token;

    if (token == null) {
      state = AsyncValue.data(local);
      return;
    }

    final previous = state.valueOrNull ?? local;
    if (previous.isEmpty) {
      state = const AsyncValue.loading();
    }

    try {
      final service = ref.read(newsServiceProvider);
      final serverBookmarks = await service.getBookmarks(token);
      final merged = _mergeBookmarks(local, serverBookmarks);
      state = AsyncValue.data(merged);
      await _saveLocalBookmarks(merged);
    } catch (e, stack) {
      if (local.isNotEmpty) {
        state = AsyncValue.data(local);
      } else {
        state = AsyncValue.error(e, stack);
      }
    }
  }

  Future<BookmarkToggleResult> toggleBookmark(Article article) async {
    article = resolveEnglishArticle(ref, article);
    if (article.id.trim().isEmpty) {
      return const BookmarkToggleResult(
        success: false,
        bookmarked: false,
        errorMessage: 'This article cannot be bookmarked.',
      );
    }

    final current = state.valueOrNull ?? await _readLocalBookmarks();
    final wasBookmarked = current.any((a) => a.id == article.id);

    final updated = List<Article>.from(current);
    if (wasBookmarked) {
      updated.removeWhere((a) => a.id == article.id);
    } else {
      updated.add(article);
    }

    state = AsyncValue.data(updated);
    await _saveLocalBookmarks(updated);

    final token = ref.read(authProvider).token;
    if (token == null) {
      return BookmarkToggleResult(success: true, bookmarked: !wasBookmarked);
    }

    try {
      final service = ref.read(newsServiceProvider);
      final result = await service.toggleBookmark(token, article);
      if (!result.success) {
        state = AsyncValue.data(current);
        await _saveLocalBookmarks(current);
        return result;
      }

      final reconciled = List<Article>.from(state.valueOrNull ?? updated);
      if (result.bookmarked) {
        if (!reconciled.any((a) => a.id == article.id)) {
          reconciled.add(article);
        }
      } else {
        reconciled.removeWhere((a) => a.id == article.id);
      }
      state = AsyncValue.data(reconciled);
      await _saveLocalBookmarks(reconciled);
      return result;
    } catch (e) {
      state = AsyncValue.data(current);
      await _saveLocalBookmarks(current);
      return BookmarkToggleResult(
        success: false,
        bookmarked: wasBookmarked,
        errorMessage: e.toString(),
      );
    }
  }

  bool isBookmarked(String articleId) {
    if (articleId.trim().isEmpty) return false;
    return state.maybeWhen(
      data: (bookmarks) => bookmarks.any((a) => a.id == articleId),
      orElse: () => false,
    );
  }
}

final bookmarksProvider =
    StateNotifierProvider<BookmarksNotifier, AsyncValue<List<Article>>>((ref) {
      ref.keepAlive();
      return BookmarksNotifier(ref);
    });


Article resolveEnglishArticle(Ref ref, Article article) {
  for (final source in [
    ref.read(recommendedFeedProvider).articles,
    ref.read(trendingNewsProvider).articles,
  ]) {
    for (final item in source) {
      if (item.id == article.id) return item;
    }
  }
  return article;
}
