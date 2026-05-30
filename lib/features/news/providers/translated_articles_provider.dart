import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_news_app/core/localization/language_provider.dart';
import 'package:flutter_news_app/models/article_model.dart';
import 'package:flutter_news_app/services/translation_service.dart';
import 'news_provider.dart';

Future<List<Article>> _translateIfNeeded(
  Ref ref,
  List<Article> articles,
) async {
  final lang = ref.watch(languageProvider);
  if (lang == 'en' || articles.isEmpty) return articles;
  return TranslationService().translateArticles(articles);
}

final trendingTranslatedProvider = FutureProvider<List<Article>>((ref) async {
  final trending = ref.watch(trendingNewsProvider);
  return _translateIfNeeded(ref, trending.articles);
});

final recommendedTranslatedProvider = FutureProvider<List<Article>>((
  ref,
) async {
  final feed = ref.watch(recommendedFeedProvider);
  return _translateIfNeeded(ref, feed.articles);
});

final bookmarksTranslatedProvider = FutureProvider<List<Article>>((ref) async {
  final bookmarks = ref.watch(bookmarksProvider);
  final list = bookmarks.valueOrNull ?? [];
  return _translateIfNeeded(ref, list);
});

final translatedArticleProvider = FutureProvider.family<Article, Article>((
  ref,
  article,
) async {
  final lang = ref.watch(languageProvider);
  if (lang == 'en') return article;
  return TranslationService().translateArticle(article);
});


Article? findArticleById(Ref ref, String articleId) {
  if (articleId.trim().isEmpty) return null;

  final bookmarks = ref.read(bookmarksProvider).valueOrNull;
  final sources = <List<Article>>[
    ref.read(recommendedFeedProvider).articles,
    ref.read(trendingNewsProvider).articles,
    if (bookmarks != null) bookmarks,
  ];

  for (final list in sources) {
    for (final article in list) {
      if (article.id == articleId) return article;
    }
  }
  return null;
}
