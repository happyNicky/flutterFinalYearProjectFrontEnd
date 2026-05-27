import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../models/article_model.dart';
import 'providers/news_provider.dart';
import 'providers/read_articles_provider.dart';
import '../../core/localization/language_provider.dart';

class ArticleDetailScreen extends ConsumerWidget {
  final Article article;
  
  const ArticleDetailScreen({super.key, required this.article});

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
    
    // Mark article as read after frame is built
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(readArticlesProvider.notifier).markAsRead(article.id);
    });

    // Watch languageProvider so the screen invalidates on language changes
    ref.watch(languageProvider);

    // Watch bookmarks state to determine if this article is saved
    final isSaved = ref.watch(bookmarksProvider).maybeWhen(
          data: (list) => list.any((a) => a.id == article.id),
          orElse: () => false,
        );

    return Scaffold(
      extendBodyBehindAppBar: true,
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 350.0,
            pinned: true,
            leading: IconButton(
              icon: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.3),
                  shape: BoxShape.circle,
                ),
                child: const Icon(LucideIcons.arrowLeft, color: Colors.white, size: 20),
              ),
              onPressed: () => context.pop(),
            ),
            actions: [
              IconButton(
                icon: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.3),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    isSaved ? Icons.bookmark : Icons.bookmark_border,
                    color: isSaved ? colorScheme.primary : Colors.white,
                    size: 20,
                  ),
                ),
                onPressed: () async {
                  final isNowBookmarked = await ref.read(bookmarksProvider.notifier).toggleBookmark(article);
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          isNowBookmarked 
                            ? context.tr('article_bookmarked', ref: ref) 
                            : context.tr('bookmark_removed', ref: ref)
                        ),
                        duration: const Duration(seconds: 1),
                      ),
                    );
                  }
                },
              ),
              IconButton(
                icon: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.3),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(LucideIcons.share2, color: Colors.white, size: 20),
                ),
                onPressed: () {
                  final shareText = '📰 *${article.title}*\n\n${article.content.length > 120 ? "${article.content.substring(0, 120)}..." : article.content}\n\n🔗 ${context.tr('read_full_article', ref: ref)}${article.id}';
                  Share.share(shareText);
                },
              ),
              const SizedBox(width: 8),
            ],
            flexibleSpace: FlexibleSpaceBar(
              background: Stack(
                fit: StackFit.expand,
                children: [
                  CachedNetworkImage(
                    imageUrl: article.imageUrl,
                    fit: BoxFit.cover,
                    placeholder: (context, url) => Container(color: Colors.black12),
                    errorWidget: (context, url, error) => Container(
                      color: Colors.grey[800],
                      child: const Icon(LucideIcons.image, color: Colors.white24, size: 48),
                    ),
                  ),
                  Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.transparent,
                          Colors.black.withOpacity(0.8),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Container(
              padding: const EdgeInsets.all(24.0),
              decoration: BoxDecoration(
                color: colorScheme.surface,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
              ),
              transform: Matrix4.translationValues(0.0, -32.0, 0.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: colorScheme.primary.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      article.category,
                      style: TextStyle(
                        color: colorScheme.primary,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    article.title,
                    style: textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: colorScheme.onSurface,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      CircleAvatar(
                        radius: 20,
                        backgroundColor: colorScheme.primary.withOpacity(0.1),
                        child: Text(
                          article.author.isNotEmpty ? article.author[0].toUpperCase() : 'A',
                          style: TextStyle(color: colorScheme.primary, fontWeight: FontWeight.bold),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              article.author,
                              style: textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            Text(
                              '${article.readTimeMinutes} ${context.tr('min_read', ref: ref)} • ${_timeAgo(context, ref, article.publishedAt)}',
                              style: textTheme.bodyMedium?.copyWith(color: colorScheme.onSurface.withOpacity(0.6)),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  Text(
                    article.content,
                    style: textTheme.bodyLarge?.copyWith(
                      height: 1.8,
                      color: colorScheme.onSurface.withOpacity(0.85),
                    ),
                  ),
                  const SizedBox(height: 32),
                  if (article.id.startsWith('http'))
                    Center(
                      child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        ),
                        onPressed: () async {
                          final uri = Uri.parse(article.id);
                          if (await canLaunchUrl(uri)) {
                            await launchUrl(uri, mode: LaunchMode.externalApplication);
                          } else {
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('Could not open article URL')),
                              );
                            }
                          }
                        },
                        icon: const Icon(LucideIcons.externalLink, size: 18),
                        label: Text('Read Full Article on Web', style: const TextStyle(fontWeight: FontWeight.bold)),
                      ),
                    ),
                  const SizedBox(height: 48), // Padding at the bottom
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
