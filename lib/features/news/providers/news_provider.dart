import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_news_app/models/article_model.dart';
import 'package:flutter_news_app/services/news_service.dart';
import 'package:flutter_news_app/features/auth/providers/auth_provider.dart';
import 'package:flutter_news_app/core/localization/language_provider.dart';
import 'package:flutter_news_app/features/news/providers/location_provider.dart';
import 'package:flutter_news_app/services/translation_service.dart';

final trendingNewsProvider = FutureProvider<List<Article>>((ref) async {
  final service = ref.read(newsServiceProvider);
  final lang = ref.watch(languageProvider);
  final articles = await service.getTrending();

  if (lang == 'am') {
    return TranslationService().translateArticles(articles);
  }
  return articles;
});

final recommendedNewsProvider = FutureProvider<List<Article>>((ref) async {
  final service = ref.read(newsServiceProvider);
  final token = ref.watch(authProvider).token;
  final locationState = ref.watch(locationProvider);
  final lang = ref.watch(languageProvider);

  final articles = await service.getRecommended(
    token: token,
    latitude: locationState.hasConsent ? locationState.latitude : null,
    longitude: locationState.hasConsent ? locationState.longitude : null,
  );

  if (lang == 'am') {
    return TranslationService().translateArticles(articles);
  }
  return articles;
});

class RecommendedFeedState {
  final List<Article> articles;
  final bool isLoading;
  final bool hasMore;
  final int page;
  final String? error;

  const RecommendedFeedState({
    this.articles = const [],
    this.isLoading = false,
    this.hasMore = true,
    this.page = 1,
    this.error,
  });

  RecommendedFeedState copyWith({
    List<Article>? articles,
    bool? isLoading,
    bool? hasMore,
    int? page,
    String? error,
  }) {
    return RecommendedFeedState(
      articles: articles ?? this.articles,
      isLoading: isLoading ?? this.isLoading,
      hasMore: hasMore ?? this.hasMore,
      page: page ?? this.page,
      error: error,
    );
  }
}

class RecommendedFeedNotifier extends StateNotifier<RecommendedFeedState> {
  final Ref ref;
  RecommendedFeedNotifier(this.ref) : super(const RecommendedFeedState()) {
    refresh();
  }

  Future<void> refresh() async {
    state = const RecommendedFeedState(isLoading: true, hasMore: true, page: 1);
    await _loadPage(reset: true);
  }

  Future<void> loadMore() async {
    if (state.isLoading || !state.hasMore) return;
    state = state.copyWith(isLoading: true, error: null);
    await _loadPage(reset: false);
  }

  Future<void> _loadPage({required bool reset}) async {
    try {
      final service = ref.read(newsServiceProvider);
      final auth = ref.read(authProvider);
      final location = ref.read(locationProvider);
      final seen = (reset ? <String>{} : state.articles.map((e) => e.id).toSet()).toList();

      final newItems = await service.getRecommended(
        token: auth.token,
        latitude: location.hasConsent ? location.latitude : null,
        longitude: location.hasConsent ? location.longitude : null,
        page: reset ? 1 : state.page,
        pageSize: 15,
        excludeIds: seen,
      );

      final merged = reset ? newItems : [...state.articles, ...newItems];
      state = state.copyWith(
        articles: merged,
        isLoading: false,
        hasMore: newItems.length >= 15,
        page: (reset ? 2 : state.page + 1),
        error: null,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Failed to fetch recommended news.',
      );
    }
  }
}

final recommendedFeedProvider =
    StateNotifierProvider<RecommendedFeedNotifier, RecommendedFeedState>((ref) {
      return RecommendedFeedNotifier(ref);
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
  final Ref ref;

  BookmarksNotifier(this.ref) : super(const AsyncValue.loading()) {
    // Listen to authentication state to fetch bookmarks when authenticated
    ref.listen(authProvider, (previous, next) {
      if (next.token != null) {
        fetchBookmarks();
      } else {
        state = const AsyncValue.data([]);
      }
    });

    // Listen to language changes to translate bookmarks if needed
    ref.listen(languageProvider, (previous, next) {
      fetchBookmarks();
    });

    // Initial fetch if already logged in
    final token = ref.read(authProvider).token;
    if (token != null) {
      fetchBookmarks();
    } else {
      state = const AsyncValue.data([]);
    }
  }

  Future<void> fetchBookmarks() async {
    final token = ref.read(authProvider).token;
    if (token == null) {
      state = const AsyncValue.data([]);
      return;
    }
    state = const AsyncValue.loading();
    try {
      final service = ref.read(newsServiceProvider);
      final bookmarks = await service.getBookmarks(token);
      final lang = ref.read(languageProvider);

      if (lang == 'am') {
        final translated = await TranslationService().translateArticles(
          bookmarks,
        );
        state = AsyncValue.data(translated);
      } else {
        state = AsyncValue.data(bookmarks);
      }
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }

  Future<bool> toggleBookmark(Article article) async {
    final token = ref.read(authProvider).token;
    if (token == null) return false;
    try {
      final service = ref.read(newsServiceProvider);
      final isBookmarkedNow = await service.toggleBookmark(token, article);

      state.whenData((currentBookmarks) {
        final List<Article> updated = List.from(currentBookmarks);
        if (isBookmarkedNow) {
          if (!updated.any((a) => a.id == article.id)) {
            updated.add(article);
          }
        } else {
          updated.removeWhere((a) => a.id == article.id);
        }
        state = AsyncValue.data(updated);
      });
      return isBookmarkedNow;
    } catch (_) {
      return false;
    }
  }

  bool isBookmarked(String articleId) {
    return state.maybeWhen(
      data: (bookmarks) => bookmarks.any((a) => a.id == articleId),
      orElse: () => false,
    );
  }
}

final bookmarksProvider =
    StateNotifierProvider<BookmarksNotifier, AsyncValue<List<Article>>>((ref) {
      return BookmarksNotifier(ref);
    });
