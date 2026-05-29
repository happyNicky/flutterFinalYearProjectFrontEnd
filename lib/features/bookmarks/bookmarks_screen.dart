import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:share_plus/share_plus.dart';
import '../news/providers/news_provider.dart';
import '../news/providers/translated_articles_provider.dart';
import '../../core/localization/language_provider.dart';

class BookmarksScreen extends ConsumerWidget {
  const BookmarksScreen({super.key});

  String _timeAgo(BuildContext context, WidgetRef ref, DateTime dateTime) {
    final difference = DateTime.now().difference(dateTime);
    if (difference.inDays >= 1) {
      return '${difference.inDays}${context.tr('d_ago', ref: ref)}';
    } else if (difference.inHours >= 1) {
      return '${difference.inHours}${context.tr('h_ago', ref: ref)}';
    } else if (difference.inMinutes >= 1) {
      return '${difference.inMinutes}${context.tr('m_ago', ref: ref)}';
    } else {
      return context.tr('just_now', ref: ref);
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    ref.watch(languageProvider);
    final bookmarksAsync = ref.watch(bookmarksTranslatedProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(context.tr('saved_articles', ref: ref), style: const TextStyle(fontWeight: FontWeight.bold)),
        actions: [
          IconButton(
            icon: const Icon(LucideIcons.refreshCw),
            onPressed: () {
              ref.read(bookmarksProvider.notifier).fetchBookmarks();
            },
          ),
        ],
      ),
      body: bookmarksAsync.when(
        data: (articles) {
          if (articles.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(LucideIcons.bookmarkPlus, size: 80, color: colorScheme.onSurface.withOpacity(0.2)),
                    const SizedBox(height: 16),
                    Text(
                      context.tr('no_saved_articles', ref: ref),
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: colorScheme.onSurface),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      context.tr('tap_bookmark_hint', ref: ref),
                      style: TextStyle(color: colorScheme.onSurface.withOpacity(0.6)),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            );
          }

          return Column();
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(child: Text(context.tr('failed_articles', ref: ref))),
      ),
    );
  }
}
