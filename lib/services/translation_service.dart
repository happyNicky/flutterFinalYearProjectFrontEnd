import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/article_model.dart';

class TranslationService {
  static final TranslationService _instance = TranslationService._internal();
  factory TranslationService() => _instance;
  TranslationService._internal();


  final Map<String, Article> _translationCache = {};

  void clearCache() {
    _translationCache.clear();
  }

  Future<String> translateText(String text, {String from = 'en', String to = 'am'}) async {
    if (text.isEmpty || from == to) return text;
    
    try {
      final encodedText = Uri.encodeComponent(text);
      final url = Uri.parse('https://api.mymemory.translated.net/get?q=$encodedText&langpair=$from|$to');
      
      final response = await http.get(url).timeout(const Duration(seconds: 3));
      
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final translatedText = data['responseData']?['translatedText'] as String?;
        if (translatedText != null && translatedText.isNotEmpty) {
          // Sometimes MyMemory returns HTML entities, decode basic ones
          return _decodeHtmlEntities(translatedText);
        }
      }
      return text;
    } catch (_) {
      
      return text;
    }
  }

  String _decodeHtmlEntities(String text) {
    return text
        .replaceAll('&quot;', '"')
        .replaceAll('&#39;', "'")
        .replaceAll('&amp;', '&')
        .replaceAll('&lt;', '<')
        .replaceAll('&gt;', '>')
        .replaceAll('&apos;', "'");
  }

  Future<Article> translateArticle(Article article) async {
    final cacheKey = '${article.id}_am';
    if (_translationCache.containsKey(cacheKey)) {
      return _translationCache[cacheKey]!;
    }

    try {
      final translatedTitle = await translateText(article.title);
      final translatedContent = await translateText(article.content);
      final translatedCategory = _translateCategory(article.category);

      final translatedArticle = Article(
        id: article.id,
        title: translatedTitle,
        content: translatedContent,
        category: translatedCategory,
        author: article.author,
        imageUrl: article.imageUrl,
        publishedAt: article.publishedAt,
        readTimeMinutes: article.readTimeMinutes,
      );

      _translationCache[cacheKey] = translatedArticle;
      return translatedArticle;
    } catch (_) {
      return article;
    }
  }

  Future<List<Article>> translateArticles(List<Article> articles) async {
    return Future.wait(articles.map((article) => translateArticle(article)));
  }

  String _translateCategory(String category) {
    final Map<String, String> categoryTranslations = {
      'general': 'አጠቃላይ',
      'technology': 'ቴክኖሎጂ',
      'sports': 'ስፖርት',
      'business': 'ንግድ',
      'science': 'ሳይንስ',
      'health': 'ጤና',
      'entertainment': 'መዝናኛ',
      'recommended': 'ለእርስዎ የተመከሩ',
      'world': 'ዓለም አቀፍ',
      'trending': 'አሁን በመታየት ላይ ያሉ',
    };

    final lower = category.toLowerCase().trim();
    return categoryTranslations[lower] ?? category;
  }
}
