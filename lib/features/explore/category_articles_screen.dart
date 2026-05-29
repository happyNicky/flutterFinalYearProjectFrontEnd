import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:share_plus/share_plus.dart';
import '../news/providers/news_provider.dart';
import '../../core/localization/language_provider.dart';

class CategoryArticlesScreen extends ConsumerWidget {
  final String? category;
  final String? query;

  const CategoryArticlesScreen({
    super.key,
    this.category,
    this.query,
  });

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

    final isCategory = category != null;
    
    // Watch languageProvider so the screen invalidates on language changes
    final lang = ref.watch(languageProvider);
    
    final translatedCategory = category != null ? _translateCategoryName(category!, ref) : null;
    final title = isCategory ? translatedCategory! : '${context.tr('search', ref: ref)}: "$query"';
    
    // Select the correct provider
    final newsAsync = isCategory
        ? ref.watch(categoryNewsProvider(category!))
        : ref.watch(searchNewsProvider(query!));

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: Icon(LucideIcons.arrowLeft, color: colorScheme.onSurface),
          onPressed: () => context.pop(),
        ),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
      ),
      body: newsAsync.when(
        data: (articles) {
          if (articles.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(LucideIcons.fileQuestion, size: 64, color: colorScheme.onSurface.withOpacity(0.2)),
                  const SizedBox(height: 16),
                  Text(
                    context.tr('no_articles_found', ref: ref),
                    style: textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    context.tr('try_another_keyword', ref: ref),
                    style: TextStyle(color: colorScheme.onSurface.withOpacity(0.5)),
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.symmetric(vertical: 12),
            itemCount: articles.length,
            itemBuilder: (context, index) {
              final article = articles[index];
              
              // Watch bookmarks state
              ref.watch(bookmarksProvider);
              final isSaved = ref.read(bookmarksProvider.notifier).isBookmarked(article.id);

              return GestureDetector(
                onTap: () => context.push('/article', extra: article),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 8.0),
                  child: Row(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(16),
                        child: CachedNetworkImage(
                          imageUrl: article.imageUrl,
                          width: 90,
                          height: 90,
                          fit: BoxFit.cover,
                          placeholder: (context, url) => Container(color: colorScheme.surfaceContainerHighest),
                          errorWidget: (context, url, error) => Container(
                            color: colorScheme.surfaceContainerHighest,
                            width: 90,
                            height: 90,
                            child: const Icon(LucideIcons.image, size: 24),
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              article.category,
                              style: TextStyle(color: colorScheme.primary, fontSize: 12, fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              article.title,
                              style: textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold, fontSize: 14),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                Icon(LucideIcons.clock, color: colorScheme.onSurface.withOpacity(0.5), size: 12),
                                const SizedBox(width: 4),
                                Text(_timeAgo(context, ref, article.publishedAt), style: TextStyle(color: colorScheme.onSurface.withOpacity(0.5), fontSize: 12)),
                                const Spacer(),
                                 IconButton(
                                  constraints: const BoxConstraints(),
                                  padding: EdgeInsets.zero,
                                  icon: Icon(
                                    LucideIcons.share2,
                                    color: colorScheme.onSurface.withOpacity(0.5),
                                    size: 18,
                                  ),
                                  onPressed: () {
                                    final shareText = '📰 *${article.title}*\n\n${article.content.length > 120 ? "${article.content.substring(0, 120)}..." : article.content}\n\n🔗 ${context.tr('read_more_at', ref: ref)}${article.id}';
                                    Share.share(shareText);
                                  },
                                ),
                                const SizedBox(width: 12),
                                IconButton(
                                  constraints: const BoxConstraints(),
                                  padding: EdgeInsets.zero,
                                  icon: Icon(
                                    isSaved ? Icons.bookmark : Icons.bookmark_border,
                                    color: isSaved ? colorScheme.primary : colorScheme.onSurface.withOpacity(0.5),
                                    size: 18,
                                  ),
                                  onPressed: () async {
                                    final result = await ref
                                        .read(bookmarksProvider.notifier)
                                        .toggleBookmark(article);
                                    if (!context.mounted || result.success) return;
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text(
                                          result.errorMessage ?? 'Bookmark failed.',
                                        ),
                                      ),
                                    );
                                  },
                                ),
                              ],
                            ),
                          ],
                        ),
                      )
                    ],
                  ),
                ),
              );
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(child: Text(context.tr('failed_articles', ref: ref))),
      ),
    );
  }

  String _translateCategoryName(String cat, WidgetRef ref) {
    final Map<String, String> translations = {
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
    final isAmharic = ref.read(languageProvider) == 'am';
    if (!isAmharic) return cat;
    final lower = cat.toLowerCase().trim();
    return translations[lower] ?? cat;
  }
}
