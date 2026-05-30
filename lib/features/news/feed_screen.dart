import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:share_plus/share_plus.dart';
import 'dart:ui';
import '../../models/article_model.dart';
import '../auth/providers/auth_provider.dart';
import 'providers/news_provider.dart';
import 'providers/location_provider.dart';
import 'providers/notification_provider.dart';
import 'providers/translated_articles_provider.dart';
import '../../core/localization/language_provider.dart';

class FeedScreen extends ConsumerStatefulWidget {
  const FeedScreen({super.key});

  @override
  ConsumerState<FeedScreen> createState() => _FeedScreenState();
}

class _FeedScreenState extends ConsumerState<FeedScreen> with WidgetsBindingObserver {
  late final ScrollController _scrollController;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _scrollController = ScrollController()..addListener(_onScroll);
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      ref.read(recommendedFeedProvider.notifier).syncNewOnResume();
      ref.read(trendingNewsProvider.notifier).syncNewOnResume();
    }
  }

  void _onScroll() {
    if (!_scrollController.hasClients) return;
    final pos = _scrollController.position;
    if (pos.pixels >= pos.maxScrollExtent - 300) {
      ref.read(recommendedFeedProvider.notifier).loadMore();
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

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
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    final authState = ref.watch(authProvider);
    final trendingNews = ref.watch(trendingNewsProvider);
    final trendingArticles = ref.watch(trendingTranslatedProvider).valueOrNull ??
        trendingNews.articles;
    final recommendedFeed = ref.watch(recommendedFeedProvider);
    final recommendedArticles =
        ref.watch(recommendedTranslatedProvider).valueOrNull ??
            recommendedFeed.articles;
    final locationState = ref.watch(locationProvider);
    final notificationCount = ref.watch(notificationBadgeCountProvider);
    ref.watch(languageProvider);

    String greetingKey() {
      final hour = DateTime.now().hour;
      if (hour >= 5 && hour < 12) {
        return 'good_morning';
      } else if (hour >= 12 && hour < 17) {
        return 'good_afternoon';
      } else {
        return 'good_evening';
      }
    }

    return Scaffold(
      backgroundColor: colorScheme.surface,
      body: SafeArea(
        bottom: false,
        child: ScrollConfiguration(
          behavior: ScrollConfiguration.of(context).copyWith(scrollbars: false),
          child: CustomScrollView(
            controller: _scrollController,
            physics: const BouncingScrollPhysics(), // Fixes the stretching issue
            slivers: [
              SliverAppBar(
                floating: true,
                pinned: true,
                elevation: 0,
                backgroundColor: colorScheme.surface.withOpacity(0.95),
                toolbarHeight: 80,
                title: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      context.tr(greetingKey(), ref: ref),
                      style: textTheme.labelLarge?.copyWith(
                        color: colorScheme.primary,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 1.2,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      authState.name ?? context.tr('guest', ref: ref),
                      style: textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.w900,
                        color: colorScheme.onSurface,
                        letterSpacing: -0.5,
                      ),
                    ),
                  ],
                ),
                actions: [
                  Container(
                    margin: const EdgeInsets.only(right: 16),
                    decoration: BoxDecoration(
                      color: colorScheme.surfaceContainerHighest.withOpacity(0.5),
                      shape: BoxShape.circle,
                    ),
                    child: Stack(
                      clipBehavior: Clip.none,
                      children: [
                        IconButton(
                          icon: Icon(LucideIcons.bell, color: colorScheme.onSurface),
                          onPressed: () => context.push('/notifications'),
                        ),
                        if (notificationCount > 0)
                          Positioned(
                            right: 6,
                            top: 6,
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                              decoration: BoxDecoration(
                                color: colorScheme.error,
                                borderRadius: BorderRadius.circular(10),
                              ),
                              constraints: const BoxConstraints(minWidth: 18, minHeight: 18),
                              child: Text(
                                notificationCount > 9 ? '9+' : '$notificationCount',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  color: colorScheme.onError,
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
              
             
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(24, 24, 24, 16),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        context.tr('trending_now', ref: ref),
                        style: textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w800,
                          letterSpacing: -0.5,
                        ),
                      ),
                      GestureDetector(
                        onTap: () => ref.read(trendingNewsProvider.notifier).refresh(),
                        child: Text(
                          context.tr('refresh', ref: ref),
                          style: textTheme.labelLarge?.copyWith(
                            color: colorScheme.primary,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              
              // Trending Cards Horizontal List
              SliverToBoxAdapter(
                child: SizedBox(
                  height: 320,
                  child: _buildTrendingSection(
                    context,
                    ref,
                    trendingNews,
                    trendingArticles,
                  ),
                ),
              ),

              // Location Permission Banner
              if (!locationState.hasAsked)
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(24, 32, 24, 0),
                    child: Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            colorScheme.primary.withOpacity(0.15),
                            colorScheme.primary.withOpacity(0.05),
                          ],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(color: colorScheme.primary.withOpacity(0.2), width: 1),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(24.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(10),
                                  decoration: BoxDecoration(
                                    color: colorScheme.primary,
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Icon(LucideIcons.mapPin, color: colorScheme.onPrimary, size: 20),
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: Text(
                                    context.tr('location_consent_title', ref: ref),
                                    style: textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            Text(
                              context.tr('location_consent_desc', ref: ref),
                              style: textTheme.bodyMedium?.copyWith(
                                color: colorScheme.onSurface.withOpacity(0.8),
                                height: 1.5,
                              ),
                            ),
                            const SizedBox(height: 20),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.end,
                              children: [
                                TextButton(
                                  onPressed: () async {
                                    await ref.read(locationProvider.notifier).revokeConsent();
                                  },
                                  child: Text(
                                    context.tr('cancel', ref: ref),
                                    style: TextStyle(color: colorScheme.onSurface.withOpacity(0.6), fontWeight: FontWeight.bold),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                ElevatedButton(
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: colorScheme.primary,
                                    foregroundColor: colorScheme.onPrimary,
                                    elevation: 4,
                                    shadowColor: colorScheme.primary.withOpacity(0.5),
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                                  ),
                                  onPressed: () async {
                                    final success = await ref.read(locationProvider.notifier).requestConsent();
                                    if (success && context.mounted) {
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        SnackBar(
                                          content: Text(context.tr('location_enabled', ref: ref)),
                                          duration: const Duration(seconds: 2),
                                          behavior: SnackBarBehavior.floating,
                                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                        ),
                                      );
                                    }
                                  },
                                  child: Text(context.tr('enable', ref: ref), style: const TextStyle(fontWeight: FontWeight.bold)),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),

              
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(24, 32, 24, 16),
                  child: Text(
                    context.tr('recommended_for_you', ref: ref),
                    style: textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.5,
                    ),
                  ),
                ),
              ),

             
              if (recommendedFeed.articles.isEmpty && recommendedFeed.isLoading)
                const SliverToBoxAdapter(
                  child: Center(
                    child: Padding(
                      padding: EdgeInsets.all(48.0),
                      child: CircularProgressIndicator(),
                    ),
                  ),
                )
              else if (recommendedFeed.articles.isEmpty)
                SliverToBoxAdapter(
                  child: Center(
                    child: Padding(
                      padding: const EdgeInsets.all(32.0),
                      child: Column(
                        children: [
                          Icon(LucideIcons.inbox, size: 48, color: colorScheme.onSurface.withOpacity(0.3)),
                          const SizedBox(height: 16),
                          Text(context.tr('no_articles_found', ref: ref), style: textTheme.titleMedium),
                        ],
                      ),
                    ),
                  ),
                )
              else
                SliverPadding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  sliver: SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (context, index) => _buildNewsListItem(
                            context,
                            ref,
                            recommendedArticles[index],
                          ),
                      childCount: recommendedArticles.length,
                    ),
                  ),
                ),
              if (recommendedFeed.isLoading && recommendedFeed.articles.isNotEmpty)
                const SliverToBoxAdapter(
                  child: Padding(
                    padding: EdgeInsets.symmetric(vertical: 16),
                    child: Center(child: CircularProgressIndicator()),
                  ),
                ),
              const SliverToBoxAdapter(child: SizedBox(height: 120)), // padding for bottom nav
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTrendingSection(
    BuildContext context,
    WidgetRef ref,
    TrendingNewsState trending,
    List<Article> articles,
  ) {
    if (trending.articles.isEmpty && trending.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (articles.isEmpty) {
      return Center(child: Text(context.tr('no_articles_found', ref: ref)));
    }

    return ListView.builder(
      physics: const BouncingScrollPhysics(),
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      itemCount: articles.length,
      itemBuilder: (context, index) {
        return _buildTrendingCard(context, ref, articles[index]);
      },
    );
  }

  Widget _buildTrendingCard(BuildContext context, WidgetRef ref, Article article) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return GestureDetector(
      onTap: () => context.push('/article', extra: article),
      child: Container(
        width: 260,
        margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(28),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.15),
              blurRadius: 20,
              offset: const Offset(0, 10),
            )
          ],
          image: DecorationImage(
            image: CachedNetworkImageProvider(article.imageUrl),
            fit: BoxFit.cover,
          ),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(28),
          child: Stack(
            children: [
              Positioned.fill(
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.transparent,
                        Colors.black.withOpacity(0.2),
                        Colors.black.withOpacity(0.85),
                      ],
                      stops: const [0.0, 0.5, 1.0],
                    ),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.end,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: BackdropFilter(
                        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                          color: colorScheme.primary.withOpacity(0.8),
                          child: Text(
                            article.category.toUpperCase(),
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 1.0,
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      article.title,
                      style: textTheme.titleMedium?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        height: 1.3,
                      ),
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Icon(LucideIcons.clock, color: Colors.white.withOpacity(0.8), size: 14),
                        const SizedBox(width: 6),
                        Text(
                          _timeAgo(context, ref, article.publishedAt),
                          style: TextStyle(color: Colors.white.withOpacity(0.8), fontSize: 12, fontWeight: FontWeight.w500),
                        ),
                      ],
                    )
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNewsListItem(BuildContext context, WidgetRef ref, Article article) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    
    final bookmarks = ref.watch(bookmarksProvider);
    final isSaved = bookmarks.maybeWhen(
      data: (list) => list.any((a) => a.id == article.id),
      orElse: () => false,
    );

    return GestureDetector(
      onTap: () => context.push('/article', extra: article),
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        decoration: BoxDecoration(
          color: colorScheme.surfaceContainerHighest.withOpacity(0.3),
          borderRadius: BorderRadius.circular(20),
        ),
        padding: const EdgeInsets.all(12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: CachedNetworkImage(
                imageUrl: article.imageUrl,
                width: 110,
                height: 110,
                fit: BoxFit.cover,
                placeholder: (context, url) => Container(color: colorScheme.surfaceContainerHighest),
                errorWidget: (context, url, error) => Container(
                  color: colorScheme.surfaceContainerHighest,
                  width: 110,
                  height: 110,
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
                    article.category.toUpperCase(),
                    style: TextStyle(
                      color: colorScheme.primary,
                      fontSize: 10,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 1.0,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    article.title,
                    style: textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      height: 1.3,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Icon(LucideIcons.clock, color: colorScheme.onSurface.withOpacity(0.5), size: 14),
                      const SizedBox(width: 4),
                      Text(
                        _timeAgo(context, ref, article.publishedAt),
                        style: TextStyle(color: colorScheme.onSurface.withOpacity(0.5), fontSize: 12, fontWeight: FontWeight.w500),
                      ),
                      const Spacer(),
                      IconButton(
                        constraints: const BoxConstraints(),
                        padding: const EdgeInsets.all(4),
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
                      const SizedBox(width: 8),
                      IconButton(
                        constraints: const BoxConstraints(),
                        padding: const EdgeInsets.all(4),
                        icon: Icon(
                          isSaved ? Icons.bookmark : Icons.bookmark_border,
                          color: isSaved ? colorScheme.primary : colorScheme.onSurface.withOpacity(0.5),
                          size: 20,
                        ),
                        onPressed: () async {
                          final result = await ref
                              .read(bookmarksProvider.notifier)
                              .toggleBookmark(article);
                          if (!context.mounted) return;
                          if (!result.success) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                  result.errorMessage ?? 'Bookmark failed.',
                                ),
                                duration: const Duration(seconds: 2),
                              ),
                            );
                          }
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
  }
}
