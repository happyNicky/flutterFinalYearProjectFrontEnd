import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

final readArticlesProvider = StateNotifierProvider<ReadArticlesNotifier, Set<String>>((ref) {
  return ReadArticlesNotifier();
});

class ReadArticlesNotifier extends StateNotifier<Set<String>> {
  ReadArticlesNotifier() : super({}) {
    _loadReadArticles();
  }

  Future<void> _loadReadArticles() async {
    final prefs = await SharedPreferences.getInstance();
    final readList = prefs.getStringList('read_articles') ?? [];
    state = readList.toSet();
  }

  Future<void> markAsRead(String articleId) async {
    if (state.contains(articleId)) return;
    final updated = {...state, articleId};
    state = updated;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList('read_articles', updated.toList());
  }
}
